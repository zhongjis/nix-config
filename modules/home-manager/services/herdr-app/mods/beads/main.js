// Beads board: every open session epic, the selected epic's tasks as a graph of `blocks` prerequisites, and an inspector
// with the picked task's remote ticket, local facts, sessions and dependencies. Opened as a tab (palette "Beads board",
// or tab.new with props.epic to preselect an epic). Read-only, except Close epic on a session epic that ended without --off.
//
// Wide (from 700 px): sessions | graph, the inspector under the graph. Narrow: the three stacked.
// Keys: Up/Down move through sessions, Enter selects one; Tab or Right/Left move between the regions; in the graph the
// arrows walk the tasks and Enter opens the task in the Agents panel. Esc cancels a Close epic question.
// Data: the session list every 30 s and the selected epic every 10 s, only while this tab shows and the window is
// visible; terminals and agents redraw by themselves. Words and times come from words.js, task rows from tasks.js.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, ScrollHandle } from "gpui-base";
import { agents, terminals, theme, settings, run, exec, props, shared, setShared, checking, window, nextCommand, panes, focused, home } from "herdr";
import { beadsDir, bdConfig, loadAllSessions, loadEpic, epicState, closeEpic } from "./bd.js";
import { buildTasks } from "./tasks.js";
import { descendants, kidStatus, treeStatus } from "./tree.js";
import { agentWord, agoText, eventWord, reportWord, reasonWord, turnWord } from "./words.js";
import { Remote } from "./remote.js";
import { driftOf, elbow, graphStep, isNewestOpen, isStale, parseKey, pickDefault, place, segments, sessionsOf, shortPath, sourceOf } from "./layout.js";

/**
 * @typedef {import("gpui-kit").Context} Cx
 * @typedef {import("gpui-kit").Color} Color
 * @typedef {Record<string, Color>} Palette
 */

const SESSION_POLL = 3, POLL = 10000;
const HIBERNATED = "panda-focus.hibernated";
// The type scale: nothing under 12 px.
const SM = 12, MD = 13, LG = 15;
// Wide layout from this width; the session column's width; the inspector's two columns from this width.
const WIDE = 700, LIST_W = 264, TWO_COLUMNS = 600;
// The graph's boxes: a card is the key row, a 2-line title, the turn row and a row per review bead.
const CARD = 224, EDGE_GAP = 32, PAD = 16, HEAD = 26, ROW_GAP = 14, ANCHOR = 19;
const REVIEW_ROW = 24;
const SIZES = { card: CARD, gap: EDGE_GAP, pad: PAD, head: HEAD, rowGap: ROW_GAP, heightOf: (t) => 102 + t.reviewers.length * (REVIEW_ROW + 4) };
const NONE = "#00000000";

/** @param {string} c @returns {c is Color} */
const isColor = (c) => c.startsWith("#");
/** theme() as the builders take it: its "#rrggbb[aa]" colors. @returns {Palette} */
function palette() {
  /** @type {Palette} */
  const out = {};
  for (const [k, v] of Object.entries(theme())) if (isColor(v)) out[k] = v;
  return out;
}
/** A color with a little alpha, for a chip's ground. @param {Color} c @returns {Color} */
const tint = (c) => `#${c.slice(1, 7)}1f`;
/** @param {string | null | undefined} url */
const prNumber = (url) => /\/pull\/(\d+)/.exec(url ?? "")?.[1];
const errorText = (e) => (e instanceof Error ? e.message : String(e));
const BEAD_STATUS = { open: "Open", in_progress: "In progress", blocked: "Blocked", closed: "Closed", deferred: "Deferred" };
const ROLE = { worker: "Worker", reviewer: "Reviewer" };

/** Whether another review of the task has the same round (parallel reviewers): then each row names its reviewer. */
const twin = (task, rv) => task.reviewers.some((o) => o !== rv && o.round === rv.round);

/** A terminal's word as the panel reads it: agents() first, then the core's; error needs the person. */
function wordOf(k, listed) {
  const own = listed.get(k.address);
  const s = own ?? (typeof k.status === "string" ? k.status : k.status?.state ?? k.report?.state) ?? "working";
  return s === "error" ? "blocked" : s;
}

/** Whether a terminal is a live one. */
const isLive = (k) => (k.state ?? "live") === "live";

/** A login shell's value of an environment variable (the app's own environment may lack it); "" when unset. @param {string} name */
async function loginVar(name) {
  const r = await exec("zsh", ["-lc", `printf %s "$${name}"`], { timeout: 10000 });
  return r.code === 0 ? r.stdout.trim() : "";
}

export default class Beads extends View {
  /** @param {unknown} _props @param {Cx} cx */
  init(_props, cx) {
    /** @type {{ items: any[] | null, error: string | null }} open session epics, as bd.loadAllSessions lists them */
    this.list = { items: null, error: null };
    /** @type {string | null} the selected epic's id */
    this.sel = null;
    /** @type {{ id: string, session: any | null, error: string | null } | null} */
    this.data = null;
    /** @type {string | null} the task the inspector shows */
    this.task = null;
    /** @type {"list" | "graph"} */
    this.region = "list";
    /** @type {string | null} the session list's keyboard row */
    this.cursor = null;
    /** @type {string | null} the epic asked "Close epic?" */
    this.confirm = null;
    this.closing = new Set();
    /** @type {Map<string, string>} */
    this.closeErrors = new Map();
    this.dir = null;
    this.tick = 0;
    /** Epic ids whose load is under way: a poll never starts a second read of the same epic. */
    this.loading = new Set();
    this.listing = false;
    // Read once: props() inside a later callback can answer for another copy.
    this.wantEpic = props()?.epic ?? null;
    this.pane = props()?.pane ?? null;
    this.wasShown = false;
    this.renderedAt = 0;
    this.probedAt = 0;
    this.size = { width: 1000, height: 640 };
    this.remote = new Remote({
      token: loginVar,
      jiraUrl: async () => {
        if (this.dir === null) this.dir = await beadsDir();
        return bdConfig(this.dir, "jira.url");
      },
      fetch: (url, options) => fetch(url, options),
    });
    this.keys = cx.focus_handle();
    this.listScroll = ScrollHandle.new();
    this.graphScroll = ScrollHandle.new();
    /** @type {Map<string, number>} task id -> its child index in the graph's scroll area, as the last render laid it out */
    this.cardIndex = new Map();
    /** What the last render drew, for the keys. */
    this.nav = { order: [], graph: null, tasks: [] };
    if (checking()) return;
    this.keys.focus();
    this.loadList(cx);
    // A hidden copy keeps running (another tab): poll only while this one shows.
    cx.timer.every(POLL, (cx) => {
      const shown = Boolean(window()?.visible) && this.isShown();
      // Several copies and no pane id to tell them apart: a redraw now shows, by the next poll, which one draws.
      const ambiguous = !this.ownPane();
      this.probedAt = Date.now();
      if (ambiguous) cx.notify();
      if (!shown) { this.wasShown = false; return; }
      this.tick++;
      // The list reload reloads the selected epic too.
      if (this.tick % SESSION_POLL === 0) this.loadList(cx); else this.loadEpicNow(cx);
      this.askRemote(cx);
    });
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "focus") this.keys.focus();
        cx.notify();
      }
    });
  }

  /** This copy's own pane: the one its props name, else the only Beads pane there is; null when it can't be told. */
  ownPane() {
    const mine = panes().filter((p) => p.mod === "beads");
    return (this.pane ? mine.find((p) => p.pane === this.pane) : mine.length === 1 ? mine[0] : null) ?? null;
  }

  /** Whether this copy is on screen. A copy that is no tab's pane (a layout block) always counts. */
  isShown() {
    const mine = panes().filter((p) => p.mod === "beads");
    if (!mine.length) return true;
    const here = focused()?.tab;
    const own = this.ownPane();
    if (own) return own.tab === here;
    // Another copy's tab being shown does not make this one shown: only a copy that drew since the last poll is.
    return mine.some((p) => p.tab === here) && this.renderedAt >= this.probedAt;
  }

  /** The addresses of the live terminals. */
  liveSet() {
    return new Set(terminals().filter((k) => typeof k.address === "string" && isLive(k)).map((k) => k.address));
  }

  /** @param {Cx} cx */
  loadList(cx) {
    if (this.listing) return;
    this.listing = true;
    cx.spawn(async (cx) => {
      try {
        if (this.dir === null) this.dir = await beadsDir();
        const items = await loadAllSessions(this.dir);
        this.list = { items, error: null };
        const ids = items.map((i) => i.epic.id);
        const want = this.wantEpic && items.find((i) => i.epic.id === this.wantEpic || i.orch === this.wantEpic);
        if (want) { this.wantEpic = null; this.sel = want.epic.id; this.cursor = want.epic.id; }
        if (!this.sel || !ids.includes(this.sel)) {
          const first = this.sorted(items, this.liveSet())[0];
          this.sel = first?.epic.id ?? null;
          this.cursor = this.sel;
          this.data = null;
          this.task = null;
        }
        this.loadEpicNow(cx);
      } catch (e) {
        this.list = { items: this.list.items, error: errorText(e) };
      } finally {
        this.listing = false;
      }
      cx.notify();
    });
  }

  /** The selected epic's tasks, comments and dependencies. A read already under way for the epic is left to finish
   * (a slow bd read must not be restarted by every poll); an answer for an epic no longer selected is dropped. @param {Cx} cx */
  loadEpicNow(cx) {
    const item = this.list.items?.find((i) => i.epic.id === this.sel);
    if (!item) return;
    const id = item.epic.id;
    if (this.loading.has(id)) return;
    this.loading.add(id);
    cx.spawn(async (cx) => {
      try {
        if (this.dir === null) this.dir = await beadsDir();
        const session = await loadEpic(item.epic, this.dir);
        if (this.sel === id) this.data = { id, session, error: null };
      } catch (e) {
        if (this.sel === id) this.data = { id, session: this.data?.id === id ? this.data.session : null, error: errorText(e) };
      } finally {
        this.loading.delete(id);
      }
      if (this.sel !== id) return;
      this.askRemote(cx);
      cx.notify();
    });
  }

  /** Asks the tracker about the picked task's ticket (kept 5 minutes). @param {Cx} cx */
  askRemote(cx) {
    const bead = this.data?.session?.beads.find((b) => b.id === this.task);
    if (bead?.external_ref) this.remote.ensure(bead.external_ref, cx);
  }

  /** Live orchestrators first, then sessions with work left, then the ones that ended without --off.
   * @param {any[]} items @param {Set<string>} live */
  sorted(items, live) {
    const rank = (i) => (i.orch && live.has(i.orch) ? 0 : isStale(i, live) ? 2 : 1);
    return [...items].sort((a, b) => rank(a) - rank(b) || Date.parse(b.epic.updated_at ?? "") - Date.parse(a.epic.updated_at ?? "") || 0);
  }

  /** @param {string} id @param {Cx} cx */
  selectEpic(id, cx) {
    this.cursor = id;
    this.confirm = null;
    if (id !== this.sel) {
      this.sel = id;
      this.task = null;
      this.data = null;
      this.loadEpicNow(cx);
    }
    cx.notify();
  }

  /** @param {string} id @param {Cx} cx */
  selectTask(id, cx) {
    this.task = id;
    const at = this.cardIndex.get(id);
    if (at !== undefined) this.graphScroll.scroll_to_item(at);
    this.askRemote(cx);
    cx.notify();
  }

  /** The two-click Close epic: the first click asks, the second (within 5 s) re-reads the epic and closes it. @param {any} item @param {Cx} cx */
  closeClick(item, cx) {
    const id = item.epic.id;
    if (this.closing.has(id)) return;
    if (this.confirm !== id) {
      if (!isStale(item, this.liveSet())) return;
      this.confirm = id;
      cx.timer.after(5000, (cx) => { if (this.confirm === id) { this.confirm = null; cx.notify(); } });
      cx.notify();
      return;
    }
    this.confirm = null;
    this.closing.add(id);
    this.closeErrors.delete(id);
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const why = await this.closeBlocker(item);
        if (why) this.closeErrors.set(id, `Not closed: ${why}`);
        else await closeEpic(this.dir ?? "", id);
      } catch (e) {
        this.closeErrors.set(id, errorText(e));
      }
      this.closing.delete(id);
      this.loadList(cx);
      cx.notify();
    });
  }

  /** What stops Close epic right now, from a fresh read (the list's counts may be 30 s old); null when nothing does.
   * @param {any} item @returns {Promise<string | null>} */
  async closeBlocker(item) {
    const { epic, children } = await epicState(this.dir ?? "", item.epic.id);
    if (!epic || epic.status === "closed") return "the epic is already closed.";
    const orch = epic.metadata.session;
    if (!orch || orch !== item.orch) return "it is no longer a session epic of this orchestrator.";
    if (children.some((c) => c.status !== "closed")) return "it has tasks that are not closed.";
    if (this.liveSet().has(orch)) return "its orchestrator is running.";
    return null;
  }

  /** Why the Agents panel can't show this epic, or null. The panel lists live orchestrators and, for each, its newest open epic.
   * @param {any} item @param {Set<string>} live */
  panelReason(item, live) {
    if (!item?.orch) return "This epic has no orchestrator.";
    if (!live.has(item.orch)) return "The panel lists live orchestrators; this one has ended.";
    if (!isNewestOpen(item, this.list.items ?? [])) return "The panel shows an orchestrator's newest open epic; this one is older.";
    return null;
  }

  /** The Agents panel, on this task's timeline (the panel reads shared "fleet.open"). The orchestrator is focused first.
   * @param {any} task @param {any} item a loadAllSessions entry */
  openInPanel(task, item) {
    run("agent.focus", { terminal: item.orch });
    setShared("fleet.open", { orch: item.orch, epic: item.epic.id, bead: task.id, at: Date.now() });
    run("layout.select", { stack: "panel-body", child: "fleet" });
    run("layout.show", { id: "panel" });
  }

  /** @param {{ key: string, modifiers: any }} e @param {Cx} cx */
  onKey(e, cx) {
    const k = parseKey(e);
    if (!k) return;
    const { order, graph } = this.nav;
    if (k === "escape") {
      if (!this.confirm) return;
      this.confirm = null;
    } else if (k === "tab" || k === "shift-tab") {
      this.region = this.region === "list" ? "graph" : "list";
    } else if (this.region === "list") {
      const at = order.indexOf(this.cursor ?? this.sel ?? "");
      if (k === "up" || k === "down") {
        this.cursor = order[Math.max(0, Math.min(order.length - 1, (at < 0 ? 0 : at) + (k === "down" ? 1 : -1)))] ?? null;
        const i = order.indexOf(this.cursor ?? "");
        if (i >= 0) this.listScroll.scroll_to_item(i);
      } else if (k === "enter" && this.cursor) {
        this.selectEpic(this.cursor, cx);
        this.region = "graph";
      } else if (k === "right") this.region = "graph";
      else return;
    } else if (graph && this.task) {
      if (k === "enter") {
        const task = this.nav.tasks.find((t) => t.id === this.task);
        const item = this.list.items?.find((i) => i.epic.id === this.sel);
        if (task && item && !this.panelReason(item, this.liveSet())) this.openInPanel(task, item);
      } else {
        const next = graphStep(graph, this.task, k);
        if (next === this.task && k === "left") this.region = "list";
        else if (next !== this.task) this.selectTask(next, cx);
      }
    } else if (k === "left") this.region = "list";
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  /** @param {Cx} cx */
  render(cx) {
    const t = palette(), now = Date.now();
    const terms = terminals().filter((k) => typeof k.address === "string");
    const listed = new Map(agents().map((a) => [a.address, a.status]));
    const live = new Set(terms.filter(isLive).map((k) => k.address));
    const items = this.sorted(this.list.items ?? [], live);
    const session = this.data && this.data.id === this.sel ? this.data.session : null;
    const tasks = session ? buildTasks({ ...session, terms, listed, hibernated: shared(HIBERNATED) ?? [], now }) : [];
    const graph = place(tasks, SIZES);
    if (tasks.length && !tasks.some((x) => x.id === this.task)) {
      this.task = pickDefault(tasks);
      cx.timer.after(0, (cx) => this.askRemote(cx));
    }
    this.nav = { order: items.map((i) => i.epic.id), graph, tasks };
    // Drawing means shown. Coming back from hidden (the poll noticed) reloads at once.
    this.renderedAt = Date.now();
    if (!checking() && !this.wasShown) {
      this.wasShown = true;
      if (this.list.items) cx.timer.after(0, (cx) => { this.loadList(cx); });
    }
    const wide = this.size.width >= WIDE;
    /** @type {any} */
    const ui = { t, now, terms, listed, live, session, tasks, graph, items, wide, home: home() };

    const sessions = this.sessionList(ui);
    const graphBox = this.graphRegion(ui);
    const inspector = this.inspector(ui);
    const body = wide
      ? h_flex().flex_1().min_h(0).min_w(0)
        .child(v_flex().w(LIST_W).flex_none().h_full().border_r_1().border_color(t.border).child(sessions))
        .child(v_flex().flex_1().min_w(0).h_full()
          .child(graphBox.flex_none())
          .child(inspector.flex_1().min_h(0)))
      : v_flex().id("beads-stack").flex_1().min_h(0).overflow_y_scrollbar()
        .child(v_flex().flex_none().h(Math.min(240, 44 + items.length * 84)).border_b_1().border_color(t.border).child(sessions))
        .child(graphBox.flex_none().border_b_1().border_color(t.border))
        .child(inspector.flex_none());
    return v_flex().id("beads").track_focus(this.keys).on_key_down((e, cx) => this.onKey(e, cx))
      .on_size_change((sz, cx) => {
        if (Math.abs(sz.width - this.size.width) > 1 || Math.abs(sz.height - this.size.height) > 1) { this.size = sz; cx.notify(); }
      })
      .size_full().min_w(0).bg(t.canvas).text_color(t.foreground).text_size(MD)
      .child(body)
      .child(this.footer(t));
  }

  /** @param {Palette} t */
  footer(t) {
    const keys = this.region === "list"
      ? "↑↓ sessions · Enter select · Tab graph"
      : "←→↑↓ tasks · Enter open in the Agents panel · Tab sessions";
    return h_flex().id("beads-footer").h(30).flex_none().px(16).gap(16).items_center().border_t_1().border_color(t.border)
      .bg(t.chrome).text_size(SM).text_color(t.muted)
      .child(div().flex_none().child(keys))
      .child(div().flex_1())
      .when(Boolean(this.dir), (el) => el.child(div().min_w(0).truncate().child(`beads ${shortPath(this.dir ?? "", home())}`)));
  }

  /** @param {Palette} t @param {string} id @param {string} label
   * @param {{ primary?: boolean, enabled?: boolean, loud?: boolean, onClick: (cx: Cx) => void }} opts */
  button(t, id, label, { primary = false, enabled = true, loud = false, onClick }) {
    return div().id(id).h(26).px(10).flex().flex_none().items_center().rounded(6).border_1().text_size(SM).font_medium()
      .border_color(loud ? t.blocked : primary ? t.solid : t.input).bg(loud ? tint(t.blocked) : primary ? t.solid : t.raised)
      .text_color(loud ? t.blocked : primary ? t.solid_foreground : t.foreground)
      .role("button").accessibility_label(label)
      .when(!enabled, (el) => el.opacity(0.5))
      .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.86)).on_click((_e, cx) => { cx.stop_propagation(); this.keys.focus(); onClick(cx); }))
      .child(label);
  }

  /** A region's title row. @param {Palette} t @param {string} title @param {string} aside */
  heading(t, title, aside) {
    return h_flex().h(36).flex_none().px(14).gap(8).items_center().text_size(SM).text_color(t.muted)
      .child(div().font_medium().child(title))
      .child(div().flex_1().min_w(0).truncate().text_right().child(aside));
  }

  // ---- sessions ----

  /** @param {any} ui */
  sessionList(ui) {
    const { t, items } = ui;
    const aside = this.list.items ? `${items.length} open` : "";
    const rows = v_flex().id("beads-sessions").flex_1().min_h(0).overflow_y_scrollbar().track_scroll(this.listScroll);
    if (!this.list.items) {
      rows.child(div().px(14).py(8).text_size(SM).line_height("18px").text_color(this.list.error ? t.blocked : t.muted)
        .child(this.list.error ? `Beads: ${this.list.error}` : "Reading sessions…"));
      if (this.list.error) rows.child(div().px(14).child(this.button(t, "list-retry", "Retry", { onClick: (cx) => this.loadList(cx) })));
    } else if (!items.length) {
      rows.child(v_flex().px(14).py(8).gap(6).text_size(SM).line_height("18px").text_color(t.muted)
        .child(div().text_color(t.foreground).font_medium().child("No open session epics"))
        .child(div().child("An epic appears here when an orchestrator starts a session.")));
    } else {
      rows.children(items.map((item) => this.sessionRow(ui, item)));
    }
    return v_flex().size_full().min_h(0)
      .child(this.heading(t, "Sessions", aside))
      .when(Boolean(this.list.error && this.list.items), (el) => el.child(div().px(14).pb(6).text_size(SM).text_color(t.blocked).child(`Beads: ${this.list.error}`)))
      .child(rows);
  }

  /** @param {any} ui @param {any} item */
  sessionRow(ui, item) {
    const { t, live, listed, terms } = ui;
    const id = item.epic.id, on = id === this.sel, cursor = this.region === "list" && id === this.cursor;
    const orchTerm = item.orch ? terms.find((k) => k.address === item.orch && (k.state ?? "live") === "live") : null;
    // As the rail and the Agents panel read it (tree.js): an orchestrator waiting on a working worker is Working.
    const state = orchTerm ? treeStatus(wordOf(orchTerm, listed), descendants(terms, orchTerm.address).map((k) => kidStatus(k, listed))) : null;
    const stale = isStale(item, live);
    const c = item.counts;
    const closed = c.closed ?? 0;
    const ink = { working: t.working, blocked: t.blocked, done: t.done, idle: t.idle }[state ?? ""] ?? t.muted;
    const segColor = { closed: t.done, active: t.working, blocked: t.blocked, open: t.input };
    const word = stale ? "ended without --off" : state ? agentWord(state) : item.orch ? "Ended" : "No orchestrator";
    const asking = this.confirm === id, busy = this.closing.has(id);
    const err = this.closeErrors.get(id);
    return v_flex().id(`ep-${id}`).flex_none().px(14).py(10).gap(6).border_l_2()
      .border_color(on ? t.accent : cursor ? t.muted : NONE).bg(on ? t.selected : NONE)
      .cursor_pointer().hover((s) => s.bg(on ? t.selected : t.hover))
      .role("button").accessibility_label(`${item.epic.title ?? id}, ${word}, ${closed} of ${c.total} closed`)
      .on_click((_e, cx) => { this.region = "list"; this.keys.focus(); this.selectEpic(id, cx); })
      .child(h_flex().gap(8).items_center().min_h(20)
        .child(state ? div().size(8).flex_none().rounded_full().bg(ink) : div().size(8).flex_none().rounded_full().border_1().border_color(t.muted))
        .child(div().flex_1().min_w(0).truncate().text_size(MD).font_medium().child(item.epic.title ?? id)))
      .child(h_flex().gap(8).items_center().h(16)
        .child(h_flex().flex_1().min_w(0).gap(2).children(segments(c).map((k) => div().h(4).flex_1().rounded(2).bg(segColor[k]))))
        .child(div().flex_none().text_size(SM).text_color(t.muted).child(`${closed}/${c.total}`)))
      .child(h_flex().gap(6).items_center().text_size(SM).text_color(t.muted)
        .child(div().flex_none().text_color(stale ? t.working : state === "blocked" ? t.blocked : t.muted).child(word))
        .child(div().flex_1().min_w(0).truncate().child(["", item.orch, sourceOf(item.epic)].filter((x, i) => i === 0 || x).join(" · "))))
      .when(Boolean(c.blocked), (el) => el.child(div().text_size(SM).text_color(t.blocked).child(`${c.blocked} blocked`)))
      .when(stale, (el) => el.child(h_flex().gap(8).items_center()
        .child(this.button(t, `close-${id}`, busy ? "Closing…" : asking ? "Close epic?" : "Close epic",
          { loud: asking, enabled: !busy, onClick: (cx) => this.closeClick(item, cx) }))
        .when(asking, (b) => b.child(div().text_size(SM).text_color(t.muted).child("Click again to close")))))
      .when(Boolean(err), (el) => el.child(div().text_size(SM).line_height("16px").text_color(t.blocked).child(err ?? "")));
  }

  // ---- graph ----

  /** The mark before a turn word. @param {Palette} t @param {any} task */
  turnStyle(t, task) {
    const result = task.life.result;
    switch (task.turn) {
      case "worker": return { ink: t.working, mark: svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900) };
      case "orch": return { ink: t.accent, mark: div().size(8).mx(2).flex_none().rounded_full().bg(t.accent) };
      case "you": return { ink: t.blocked, loud: true, mark: div().size(8).mx(2).flex_none().rounded_full().bg(t.blocked) };
      case "done":
        if (!task.life.settled || result === "succeeded") return { ink: t.done, mark: svg("mods/workspace-chrome/check.svg").size(12).flex_none().text_color(t.done) };
        // Closed without a settle: done, its outcome unknown, so not green.
        if (result === "closed") return { ink: t.muted, mark: svg("mods/workspace-chrome/check.svg").size(12).flex_none().text_color(t.muted) };
        return { ink: result === "failed" ? t.blocked : t.muted, mark: svg("mods/workspace-chrome/x.svg").size(12).flex_none().text_color(result === "failed" ? t.blocked : t.muted) };
      case "waiting":
      case "slot": return { ink: t.muted, mark: svg("mods/workspace-chrome/clock.svg").size(12).flex_none().text_color(t.muted) };
      default: return { ink: t.muted, mark: div().size(8).mx(2).flex_none().rounded_full().border_1().border_color(t.muted) };
    }
  }

  /** @param {any} ui @param {any} task */
  turnChip(ui, task) {
    const { t } = ui;
    const s = this.turnStyle(t, task);
    return h_flex().h(20).gap(5).flex_none().items_center().text_size(SM).min_w(0)
      .when(Boolean(s.loud), (el) => el.px(6).rounded(5).bg(tint(t.blocked)).font_medium())
      .text_color(s.ink).child(s.mark).child(div().min_w(0).truncate().child(turnWord(task)));
  }

  /** @param {any} ui @param {any} task @param {any} node */
  card(ui, task, node) {
    const { t, listed } = ui;
    const sel = this.task === task.id, active = this.region === "graph";
    const pr = prNumber(task.life.pr);
    return v_flex().id(`g-${task.id}`).absolute().left(node.x).top(node.y).w(node.w).h(node.h).px(10).py(8).gap(4).rounded(10).overflow_hidden()
      .bg(sel ? t.selected : t.background).border_1().border_color(sel ? (active ? t.accent : t.input) : t.border)
      .cursor_pointer().hover((s) => s.border_color(sel && active ? t.accent : t.input))
      .role("button").accessibility_label(`${task.key}, ${task.title}, ${turnWord(task)}`)
      .on_click((_e, cx) => { this.region = "graph"; this.keys.focus(); this.selectTask(task.id, cx); })
      .child(h_flex().h(20).gap(8).items_center().text_size(SM)
        .child(div().flex_none().font_medium().child(task.key))
        .child(div().flex_1().min_w(0))
        .when(Boolean(pr), (el) => el.child(div().flex_none().text_color(t.muted).child(`PR #${pr}`))))
      .child(div().h(36).overflow_hidden().text_size(MD).line_height("18px").child(task.title))
      .child(this.turnChip(ui, task))
      .children(task.reviewers.map((rv) => {
        const word = rv.bead.status === "closed" ? "closed" : rv.worker ? agentWord(rv.worker.status).toLowerCase() : (BEAD_STATUS[rv.bead.status] ?? "open").toLowerCase();
        return h_flex().h(REVIEW_ROW).flex_none().px(6).gap(6).items_center().rounded(6).bg(t.canvas).border_1().border_color(t.border)
          .text_size(SM).text_color(t.muted).child(div().min_w(0).truncate().child(`Review r${rv.round}${twin(task, rv) ? ` · ${rv.bead.assignee ?? rv.bead.id}` : ""} · ${word}`));
      }));
  }

  /** @param {any} ui */
  graphRegion(ui) {
    const { t, graph, tasks, session } = ui;
    const byId = new Map(tasks.map((x) => [x.id, x]));
    const steps = graph.cols.length;
    const head = this.heading(t, session ? `${session.epic.title ?? session.epic.id}` : "Tasks",
      session ? `${tasks.length} ${tasks.length === 1 ? "task" : "tasks"} · ${steps} ${steps === 1 ? "step" : "steps"}${session.mode?.flags ? ` · ${session.mode.flags}` : ""}` : "");
    const message = (text, retry) => v_flex().px(14).pb(14).gap(8).items_start().text_size(SM).line_height("18px")
      .text_color(this.data?.error ? t.blocked : t.muted).child(text)
      .when(Boolean(retry), (el) => el.child(this.button(t, "graph-retry", "Retry", { onClick: (cx) => this.loadEpicNow(cx) })));
    const frame = (inner, h) => v_flex().id("beads-graph").flex_none().h(h).child(head).child(inner);
    if (!this.sel) return frame(message(this.list.items ? "Pick a session to see its tasks." : "", false), 120);
    if (!session) {
      return frame(message(this.data?.error ? `Beads: ${this.data.error}` : "Reading tasks…", Boolean(this.data?.error)), 120);
    }
    const note = this.data?.error ? div().px(14).pb(6).text_size(SM).text_color(t.blocked).child(`Beads: ${this.data.error}`) : null;
    if (!tasks.length) return frame(message("This epic has no tasks yet.", false), 120);
    // The scroll area's children are the connectors, headers and cards themselves (absolute, from its corner), after one
    // sized spacer that gives it its extent: scroll_to_item reveals a direct child, so a selected card can be brought into view.
    const scroll = v_flex().id("beads-graph-scroll").relative().flex_1().min_h(0).overflow_scrollbar().track_scroll(this.graphScroll)
      .child(div().flex_none().w(graph.width).h(graph.height));
    this.cardIndex = new Map();
    let child = 1;
    const put = (el) => { scroll.child(el); child++; };
    // Connectors first, so a card hides a line that runs behind it. A line is green once its prerequisite is closed.
    for (const e of graph.edges) {
      const a = graph.nodes.get(e.from), b = graph.nodes.get(e.to);
      const ink = byId.get(e.from)?.status === "closed" ? t.done : t.muted;
      for (const p of elbow({ x: a.x + a.w, y: a.y + ANCHOR }, { x: b.x, y: b.y + ANCHOR }, 6)) {
        const box = div().absolute().left(p.x).top(p.y).w(p.w).h(p.h);
        if (!p.corner) put(box.bg(ink));
        else {
          box.border_color(ink);
          if (p.corner === "tr") box.border_t_1().border_r_1().rounded_tr(p.r);
          else if (p.corner === "br") box.border_b_1().border_r_1().rounded_br(p.r);
          else if (p.corner === "bl") box.border_l_1().border_b_1().rounded_bl(p.r);
          else box.border_t_1().border_l_1().rounded_tl(p.r);
          put(box);
        }
      }
    }
    graph.cols.forEach((_ids, c) => put(div().absolute().left(PAD + c * (CARD + EDGE_GAP)).top(PAD).h(HEAD).w(CARD).flex().items_center()
      .text_size(SM).text_color(t.muted).child(c === 0 ? "Step 1 · no prerequisites" : `Step ${c + 1}`)));
    for (const task of tasks) {
      this.cardIndex.set(task.id, child);
      put(this.card(ui, task, graph.nodes.get(task.id)));
    }
    const natural = graph.height + 36 + (note ? 24 : 0);
    const h = ui.wide ? Math.max(160, Math.min(natural, Math.floor((this.size.height - 30) * 0.5))) : Math.min(natural, 460);
    return v_flex().id("beads-graph").flex_none().h(h).child(head).when(Boolean(note), (el) => el.child(note))
      .child(scroll);
  }

  // ---- inspector ----

  /** A section: a title and a rule. @param {Palette} t @param {string} title @param {any} body */
  section(t, title, body) {
    return v_flex().gap(8).min_w(0)
      .child(h_flex().gap(8).items_center().text_size(SM).font_medium().text_color(t.muted)
        .child(div().flex_none().child(title)).child(div().flex_1().h(1).bg(t.border)))
      .child(body);
  }

  /** A label and its value. @param {Palette} t @param {string} label @param {any} value @param {{ mono?: boolean, ink?: Color }} [o] */
  fact(t, label, value, o = {}) {
    const val = typeof value === "string"
      ? div().flex_1().min_w(0).line_height("18px").text_size(SM).text_color(o.ink ?? t.foreground).child(value) : value;
    if (o.mono && typeof value === "string") val.font_family(String(settings()?.font_family ?? "JetBrains Mono"));
    return h_flex().gap(10).items_start().text_size(SM)
      .child(div().w(72).flex_none().text_color(t.muted).child(label)).child(val);
  }

  /** @param {any} ui */
  inspector(ui) {
    const { t, session, tasks } = ui;
    const root = v_flex().id("beads-inspector").min_w(0).overflow_y_scrollbar().px(16).py(14).gap(16);
    if (!session) return root.child(div().text_size(SM).text_color(t.muted).child(this.sel ? "" : "Select a session."));
    const task = tasks.find((x) => x.id === this.task);
    if (!task) {
      return root.child(div().text_size(LG).font_semibold().child(session.epic.title ?? session.epic.id))
        .child(div().text_size(SM).text_color(t.muted).child("Add tasks under this epic to see their tickets and sessions here."));
    }
    const bead = session.beads.find((b) => b.id === task.id);
    const item = ui.items.find((i) => i.epic.id === session.epic.id);
    const reason = this.panelReason(item, ui.live);
    const pr = prNumber(task.life.pr);
    const lead = v_flex().gap(8).min_w(0)
      .child(div().text_size(LG).line_height("20px").font_semibold().child(task.title))
      .child(h_flex().gap(10).items_center().flex_wrap().text_size(SM).text_color(t.muted)
        .child(div().font_medium().text_color(t.foreground).child(task.key))
        .child(div().child(BEAD_STATUS[task.status] ?? task.status))
        .when(Boolean(pr), (el) => el.child(div().child(`PR #${pr}`)))
        .child(this.turnChip(ui, task)))
      .child(h_flex().gap(10).items_center().flex_wrap()
        .child(this.button(t, "open-panel", "Open in Agents panel", { primary: true, enabled: !reason, onClick: () => this.openInPanel(task, item) }))
        .when(Boolean(reason), (el) => el.child(div().text_size(SM).text_color(t.muted).child(reason ?? ""))));
    const left = [this.remoteSection(ui, task, bead), this.localSection(ui, task, bead), this.depsSection(ui, task)];
    const right = [this.sessionsSection(ui, task), this.eventsSection(ui, task, bead ? item : null, reason)];
    const two = this.size.width - (ui.wide ? LIST_W : 0) >= TWO_COLUMNS;
    return root.child(lead).child(two
      ? h_flex().gap(28).items_start()
        .child(v_flex().flex_1().min_w(0).gap(16).children(left))
        .child(v_flex().flex_1().min_w(0).gap(16).children(right))
      : v_flex().gap(16).children([...left, ...right]));
  }

  /** @param {any} ui @param {any} task @param {any} bead */
  remoteSection(ui, task, bead) {
    const { t, now } = ui;
    const info = this.remote.peek(bead?.external_ref);
    const ref = info.ref;
    const rows = [];
    if (!bead?.external_ref) rows.push(div().text_size(SM).text_color(t.muted).child("Not linked to a ticket."));
    else {
      const label = ref?.key ?? "Ticket";
      const where = ref?.provider === "linear" ? "Linear" : ref?.provider === "jira" ? "Jira" : "";
      rows.push(this.fact(t, "Ticket", h_flex().id("remote-link").flex_1().min_w(0).min_h(24).items_center().gap(6).cursor_pointer()
        .role("button").accessibility_label(`Open ${label} in the browser`).tooltip(bead.external_ref)
        .text_size(SM).text_color(t.accent).hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => { if (task.url) cx.open_url(task.url); })
        .child(div().min_w(0).truncate().underline().child([where, label].filter(Boolean).join(" "))), {}));
      if (info.kind === "known" && info.status === "ok") {
        const v = info.value;
        const dot = v.color && v.color.startsWith("#") ? v.color : { done: t.done, active: t.working, canceled: t.muted }[v.kind] ?? t.muted;
        rows.push(this.fact(t, "State", h_flex().flex_1().min_w(0).gap(6).items_center().text_size(SM)
          .child(div().size(8).flex_none().rounded_full().bg(dot))
          .child(div().min_w(0).truncate().child(v.state))
          .child(div().flex_none().text_color(t.muted).child(v.updatedAt ? `· updated ${agoText(v.updatedAt, now)}` : ""))));
      } else if (info.kind === "known" && info.status === "no-token") {
        rows.push(this.fact(t, "State", `Set ${info.variable} in your login shell (zsh) to read the ticket's state.`, { ink: t.muted }));
      } else if (info.kind === "known") {
        rows.push(this.fact(t, "State", info.message, { ink: t.blocked }));
      } else if (info.kind === "none") {
        // A Jira ref off bd's jira.url says why it isn't read; any other tracker isn't read here at all.
        rows.push(this.fact(t, "State", info.note ?? "This tracker's state isn't read here.", { ink: t.muted }));
      } else {
        rows.push(this.fact(t, "State", "Reading…", { ink: t.muted }));
      }
    }
    const drift = driftOf(task.events);
    if (drift) rows.push(this.fact(t, "Drift", `${drift.text}${drift.at ? ` · ${agoText(drift.at, now)}` : ""}`, { ink: t.working }));
    return this.section(t, "Remote", v_flex().gap(6).children(rows));
  }

  /** @param {any} ui @param {any} task @param {any} bead */
  localSection(ui, task, bead) {
    const { t } = ui;
    const md = bead?.metadata ?? {};
    const dispatched = [...task.events].reverse().find((e) => e.fields.worktree);
    const worktree = dispatched?.fields.worktree ?? md.worktree;
    const head = task.life.head ?? md.head_sha;
    const facts = [
      ["Repo", md.repo, false], ["Branch", md.branch, true], ["Base", md.base, true],
      ["Head", head ? head.slice(0, 7) : null, true], ["Worktree", worktree ? shortPath(worktree, ui.home) : null, true],
      ["Labels", bead?.labels?.length ? bead.labels.join(", ") : null, false],
    ].filter(([, v]) => v);
    return this.section(t, "Local", v_flex().gap(6)
      .children(facts.length ? facts.map(([l, v, mono]) => this.fact(t, String(l), String(v), { mono: Boolean(mono) }))
        : [div().text_size(SM).text_color(t.muted).child("Nothing recorded yet.")]));
  }

  /** @param {any} ui @param {any} task */
  depsSection(ui, task) {
    const { t, tasks, session } = ui;
    const byId = new Map(tasks.map((x) => [x.id, x]));
    const prereq = session.deps[task.id] ?? [];
    const row = (id, key, note) => {
      const there = byId.has(id);
      return h_flex().id(`dep-${id}`).min_h(24).gap(8).items_center().text_size(SM)
        .when(there, (el) => el.cursor_pointer().hover((s) => s.bg(t.hover)).role("button").accessibility_label(`Show ${key}`)
          .on_click((_e, cx) => { this.region = "graph"; this.keys.focus(); this.selectTask(id, cx); }))
        .child(div().flex_none().font_medium().text_color(there ? t.accent : t.foreground).child(key))
        .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(note));
    };
    const lines = [
      ...prereq.map((d) => {
        const other = byId.get(d.id);
        const done = (other?.status ?? d.status) === "closed";
        return row(d.id, other?.key ?? d.id, done ? "closed · prerequisite met" : `${BEAD_STATUS[other?.status ?? d.status] ?? "open"} · blocks this task`);
      }),
      ...task.blocks.map((b) => row(b.id, b.key, "waits on this task")),
    ];
    return this.section(t, "Dependencies", v_flex().gap(2)
      .children(lines.length ? lines : [div().text_size(SM).text_color(t.muted).child("No prerequisites, and nothing waits on it.")]));
  }

  /** @param {any} ui @param {any} task */
  sessionsSection(ui, task) {
    const { t } = ui;
    const rows = sessionsOf(task, { terms: ui.terms, listed: ui.listed, hibernated: shared(HIBERNATED) ?? [] });
    const ink = { working: t.working, blocked: t.blocked, done: t.done, idle: t.idle, failed: t.blocked };
    const mono = String(settings()?.font_family ?? "JetBrains Mono");
    const one = (s) => {
      const isUp = s.term && isLive(s.term);
      const key = `${s.name}-${s.round}`;
      const word = s.state === "gone" ? "No terminal left" : agentWord(s.state);
      const where = [s.address, s.role === "reviewer" && s.round ? `review r${s.round}` : ROLE[s.role]].filter(Boolean).join(" · ");
      return v_flex().id(`sess-${key}`).gap(4).py(2)
        .child(h_flex().gap(8).items_center().text_size(MD)
          .child(div().flex_1().min_w(0).truncate().font_medium().child(s.name))
          .child(div().flex_none().text_size(SM).text_color(ink[s.state] ?? t.muted).child(word)))
        .child(div().text_size(SM).text_color(t.muted).truncate().child(where))
        .when(Boolean(s.resume), (el) => el.child(div().id(`resume-${key}`).text_size(SM).text_color(t.muted).truncate().font_family(mono).tooltip(s.resume ?? "").child(s.resume ?? "")))
        .child(h_flex().gap(8).flex_wrap()
          .when(Boolean(isUp), (el) => el.child(this.button(t, `focus-${key}`, "Focus", { primary: true, onClick: () => run("agent.focus", { terminal: s.address }) })))
          .when(Boolean(s.term), (el) => el.child(this.button(t, `peek-${key}`, "Peek", { onClick: () => run("terminal.peek", { terminal: s.address }) })))
          .when(s.state === "gone", (el) => el.child(div().text_size(SM).text_color(t.muted).child("Reaped or closed."))));
    };
    return this.section(t, "Sessions", v_flex().gap(12)
      .children(rows.length ? rows.map(one) : [div().text_size(SM).text_color(t.muted).child("No terminal has touched this task yet.")]));
  }

  /** @param {any} ui @param {any} task @param {any} item the epic's list entry, when the panel may be linked @param {string | null} reason why it may not */
  eventsSection(ui, task, item, reason) {
    const { t, now } = ui;
    const events = [...task.events].reverse().slice(0, 5);
    const older = task.events.length - events.length;
    const facts = (e) => [e.fields.reason ? reasonWord(e.fields.reason) : null, prNumber(e.fields.pr) ? `PR #${prNumber(e.fields.pr)}` : null,
      e.fields.head ? e.fields.head.slice(0, 7) : null, e.fields.agent ?? null, e.fields.result ?? null].filter(Boolean).join(" · ");
    const row = (e, i) => v_flex().id(`ev-${i}`).gap(1).py(2)
      .child(h_flex().gap(8).items_center().text_size(SM)
        .child(div().flex_none().font_medium().text_color(i === 0 ? t.foreground : t.muted).child(e.name === "report" ? reportWord(e.fields.kind) || eventWord("report") : eventWord(e.name)))
        .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(facts(e)))
        .child(div().flex_none().text_color(t.muted).child(e.at ? agoText(e.at, now) : "")));
    return this.section(t, "Newest events", v_flex().gap(4)
      .children(events.length ? events.map(row) : [div().text_size(SM).text_color(t.muted).child("No events on this task yet.")])
      .when(Boolean(item) && !reason, (el) => el.child(h_flex().id("events-timeline").min_h(24).items_center().cursor_pointer()
        .role("button").accessibility_label("Open the timeline in the Agents panel")
        .text_size(SM).text_color(t.accent).hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => { cx.stop_propagation(); this.keys.focus(); this.openInPanel(task, item); })
        .child(div().min_w(0).truncate().underline().child(older ? `${older} older in the Agents panel timeline` : "Open the timeline in the Agents panel"))))
      .when(Boolean(item) && Boolean(reason) && older > 0, (el) => el.child(div().text_size(SM).text_color(t.muted).child(`${older} older events.`))));
  }
}
