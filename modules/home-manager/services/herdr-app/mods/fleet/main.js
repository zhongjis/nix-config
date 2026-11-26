// Agents panel: the focused agent (focused().agent: the one picked in panda-focus's rail, or the focused pane's)
// with its sub-agents, tools and tasks down a spine. The rail is the agent list; this panel only follows it, as
// herdr-panda's right panel (`panel-body` child `fleet`, beside Files, Changes, PR and CI). Picking a card shows its
// detail in the tree's place, with a way back: bead events, the last screen lines, Focus / Peek / Keep / Answer.
// The arrows, Enter and Esc also arrive as fleet.<up|down|left|enter|escape> commands (keys.json, herdr-app
// do); fleet.fixture / fleet.live switch between sample and live beads.
// Herdr's live data (agents, terminals) redraws it by itself; only live beads poll, every 10 s while it shows.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, terminals, spaces, theme, settings, run, hc, checking, window, nextCommand, layout, focused } from "herdr";
import { buildFleet, descendants, STEPS, age } from "./model.js";
import { fixtureEpics } from "./fixtures.js";
import { beadsDir, loadLive } from "./beads.js";

/**
 * @typedef {import("gpui-kit").Context} Cx
 * @typedef {import("gpui-kit").Color} Color
 * @typedef {import("gpui-kit").KeyEvent} KeyEvent
 * @typedef {import("./model.js").FleetNode} Node
 * @typedef {import("./model.js").ShownRoot} ShownRoot
 * @typedef {import("./model.js").Epic} Epic
 * @typedef {import("./model.js").BeadEvent} BeadEvent
 * @typedef {Record<string, Color>} Palette
 * @typedef {{ child: number }} Sizes
 * @typedef {{ t: Palette, now: number, size: Sizes }} Ui
 * @typedef {{ kids: string[], byId: Map<string, Node> }} Nav
 * @typedef {{ id: string, state: "loading" | "ready" | "error" | "none", lines: string[], error?: string }} Screen
 */

const POLL = 10000;
// The screen tail's rows: a fixed line height, so the block can be sized to them (a scroll area sizes to nothing).
const LINE = 18;
// herdr-panda's right panel, its stack, and this block's child id in it.
const PANEL = "panel", BODY = "panel-body", SELF = "fleet";
// How long a screen read may take before the detail says it's unavailable (ms).
const SCREEN_WAIT = 4000;
// Bead events shown before "Show all".
const EVENTS = 5;
// Connector geometry: the stub from a root to its spine, each child's arm, and where a line meets a card
// (the middle of its icon tile: 11 px padding + 12).
const ARM = 22, ANCHOR = 23, GAP = 10;
// The type scale: metadata, body, names, titles.
const XS = 11, SM = 12, MD = 13, LG = 15;
const ME = "mods/fleet";

/** What a badge says for each shown state. @type {Record<string, string>} */
const LABEL = {
  working: "Working", supervising: "Supervising", running: "Running", blocked: "Needs you", failed: "Failed",
  done: "Done", idle: "Idle", queued: "Queued", ended: "Ended", sample: "Sample",
};

/** @param {string} c @returns {c is Color} */
const isColor = (c) => c.startsWith("#");
/** theme() as the builders take it: its "#rrggbb[aa]" colors. @returns {Palette} */
function palette() {
  /** @type {Palette} */
  const out = {};
  for (const [k, v] of Object.entries(theme())) if (isColor(v)) out[k] = v;
  return out;
}
/** A status color with a little alpha, for a badge's ground. @param {Color} c @returns {Color} */
const tint = (c) => `#${c.slice(1, 7)}1f`;
/** @param {string | null | undefined} url */
const prNumber = (url) => /\/pull\/(\d+)/.exec(url ?? "")?.[1];
/** @param {import("./model.js").Life} life @param {number} i */
const stepLabel = (life, i) => (i === 2 && life.round ? `review r${life.round}` : STEPS[i]);
/** The last `n` screen lines, without the blank rows around them. @param {string} text @param {number} n */
function tail(text, n) {
  const lines = text.split("\n").map((l) => l.replace(/\s+$/, ""));
  while (lines.length && !lines.at(-1)) lines.pop();
  const last = lines.slice(-n);
  while (last.length && !last[0]) last.shift();
  return last;
}
/** Core terminals as the model reads them: entries with an address. @returns {import("./model.js").Term[]} */
const coreTerminals = () => terminals().flatMap((k) => (typeof k.address === "string" ? [{ ...k, address: k.address }] : []));
/** A tree card's width for the row's width: a wide work area gets wider cards. @param {number} width @returns {Sizes} */
const sizesFor = (width) => ({ child: width >= 2000 ? 440 : width >= 1400 ? 380 : 300 });
/** A layout node by id, in layout()'s tree (clicks included: a selected stack child is its `active`).
 * @param {unknown} node @param {string} id @returns {Record<string, unknown> | null} */
function findNode(node, id) {
  if (!node || typeof node !== "object") return null;
  const o = Object.fromEntries(Object.entries(node));
  if (o.id === id) return o;
  for (const c of Array.isArray(o.children) ? o.children : []) { const f = findNode(c, id); if (f) return f; }
  return null;
}
/** How deep a tree goes below its root (children: 1). @param {Node} n @returns {number} */
const depthOf = (n) => (n.children.length ? 1 + Math.max(...n.children.map(depthOf)) : 0);
/** An hc call that never rejects: a failure to start reads as a nonzero exit. @param {string[]} args */
const hcSafe = (args) => hc(args).catch((e) => ({ code: 1, stdout: "", stderr: e instanceof Error ? e.message : String(e) }));
/** An event's body, cut to its first lines: the events list is a timeline, not a reader. @param {string} body */
function brief(body) {
  const lines = body.split("\n").filter((l) => l.trim());
  const text = lines.slice(0, 3).join("\n");
  return lines.length > 3 || text.length > 360 ? `${text.slice(0, 360).trimEnd()}…` : text;
}
/** A live agent that can be typed to: not one that's finished. @param {Node} n */
const answerable = (n) => n.kind === "agent" && n.live && Boolean(n.address) && n.status !== "done" && n.status !== "ended";
/** What each bead event is called; a report by its kind. @type {Record<string, string>} */
const EVENT = {
  dispatched: "Dispatched", "re-instructed": "Re-instructed", decided: "Decided", note: "Note", reaped: "Reaped",
  "handed-off": "Handed off", adopted: "Adopted", blocked: "Blocked", ready: "Ready", queued: "Queued", mode: "Mode",
};
/** @type {Record<string, string>} */
const REPORT = { "pr-opened": "PR opened", "ready-local": "Ready for local review", done: "Reported done" };
/** @param {BeadEvent} e */
const eventName = (e) => (e.name === "report" ? REPORT[e.fields.kind] ?? "Report"
  : EVENT[e.name] ?? e.name.replace(/-/g, " ").replace(/^./, (c) => c.toUpperCase()));
/** An event's few facts worth a glance (its PR, commit, who), not every field. @param {BeadEvent} e */
function eventFacts(e) {
  const f = e.fields, pr = prNumber(f.pr);
  return [pr ? `PR #${pr}` : null, f.head ? f.head.slice(0, 7) : null, f.agent ?? null, f.by ? `by ${f.by}` : null,
    e.name === "decided" && f.a ? f.a : null].filter(Boolean).join(" · ");
}
/** An event body's first line. @param {string} body */
const firstLine = (body) => body.split("\n").find((l) => l.trim())?.trim() ?? "";
/** "idle 3h", "needs you 12m", "settled 40m": how long the state it names has held. @param {Node} n @param {number} now */
function ageLabel(n, now) {
  const a = age(n.since, now);
  if (!a) return null;
  const word = n.kind === "bead" ? n.events.at(-1)?.name ?? n.bead?.status ?? "updated" : (LABEL[n.status] ?? n.status).toLowerCase();
  return `${word} ${a}`;
}

export default class Fleet extends View {
  /** @param {unknown} _props @param {Cx} cx */
  init(_props, cx) {
    /** @type {"fixture" | "live"} live beads unless fleet.fixture asks for the sample */
    this.mode = "live";
    // Whether the last render showed it: showing anew refreshes live beads.
    this.wasShown = false;
    // Live beads: the last answer, kept while a refresh runs; error names why bd couldn't answer.
    /** @type {{ byOrch: Map<string, Epic[]> | null, error: string | null, loading: boolean }} */
    this.live = { byOrch: null, error: null, loading: false };
    /** @type {string | null} the login shell's BEADS_DIR, asked once */
    this.beadsDir = null;
    this.fixtureAt = Date.now();
    /** @type {string | null} the agent shown, as last seen: picking another one closes the detail */
    this.selAddr = null;
    /** @type {string | null} the keyboard's card */
    this.cursor = null;
    /** @type {string | null} the card whose detail shows */
    this.detail = null;
    /** @type {Node | null} */
    this.detailNode = null;
    /** @type {Screen | null} */
    this.screen = null;
    this.width = 1400;
    /** @type {Nav} what the last render drew, for keys and commands */
    this.nav = { kids: [], byId: new Map() };
    this.typing = false;
    this.sending = false;
    this.keys = cx.focus_handle();
    this.answer = InputState.new({ placeholder: "Answer this agent…" });
    this.answer.on("submit", (_e, cx) => this.send(cx));
    this.answer.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.answer.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    if (checking()) return;
    if (this.isShown()) this.loadBeads(cx);
    // A hidden copy keeps running (the stack's other child, another tab): poll only while this one shows.
    cx.timer.every(POLL, (cx) => { if (this.mode === "live" && window()?.visible && this.isShown()) this.loadBeads(cx); });
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "fixture" || c === "live") this.setMode(c, cx);
        else if (c === "focus") this.keys.focus();
        else if (this.walk(c, cx)) cx.notify();
      }
    });
  }

  /** Whether the right panel shows, with this block picked. */
  isShown() {
    const root = layout(), body = findNode(root, BODY);
    const active = body?.active ?? (Array.isArray(body?.children) ? body.children[0]?.id : null);
    return findNode(root, PANEL)?.hidden !== true && active === SELF;
  }

  /** Orchestrators' epics from bd, with the login shell's BEADS_DIR. On failure the cards keep what they had and
   * the header says why. @param {Cx} cx */
  loadBeads(cx) {
    if (this.live.loading) return;
    const orchs = buildFleet({ agents: agents(), terminals: coreTerminals(), spaces: spaces() }).roots
      .flatMap((r) => (r.orch && r.node.address ? [r.node.address] : []));
    this.live = { ...this.live, loading: true };
    if (!this.live.byOrch) cx.notify();
    cx.spawn(async (cx) => {
      try {
        if (this.beadsDir === null) this.beadsDir = await beadsDir();
        this.live = { byOrch: await loadLive(orchs, this.beadsDir), error: null, loading: false };
      } catch (e) {
        this.live = { ...this.live, error: e instanceof Error ? e.message : String(e), loading: false };
      }
      cx.notify();
    });
  }

  /** @param {"fixture" | "live"} mode @param {Cx} cx */
  setMode(mode, cx) {
    if (mode === this.mode) return;
    this.mode = mode;
    this.detail = null;
    if (mode === "live") this.loadBeads(cx);
    cx.notify();
  }

  /** Shows a card's detail and reads its screen; `answer` puts the keyboard in the answer field.
   * @param {Node} node @param {Cx} cx @param {boolean} [answer] */
  openDetail(node, cx, answer = false) {
    this.detail = node.id;
    this.cursor = node.id;
    this.note = null;
    this.expanded = new Set();
    this.allEvents = false;
    this.answer.set_value("");
    this.readScreen(node, cx);
    // The field draws on the next frame; focus it then too.
    if (answer && answerable(node)) { this.answer.focus(); cx.timer.after(60, () => this.answer.focus()); }
    cx.notify();
  }

  /** Reads a card's last screen lines; a read that doesn't answer in SCREEN_WAIT says so, and can be retried.
   * @param {Node} node @param {Cx} cx */
  readScreen(node, cx) {
    const id = node.id, address = node.live ? node.address : null;
    this.screen = { id, state: address ? "loading" : "none", lines: [] };
    if (!address) return;
    const at = Date.now();
    this.screenAt = at;
    cx.spawn(async (cx) => {
      const r = await hcSafe(["read", address, "--lines", "20"]);
      if (this.screen?.id !== id || this.screenAt !== at) return;
      this.screen = r.code === 0 ? { id, state: "ready", lines: tail(r.stdout, 20) }
        : { id, state: "error", lines: [], error: r.stderr.trim() || `hc read exited ${r.code}` };
      cx.notify();
    });
    cx.timer.after(SCREEN_WAIT, (cx) => {
      if (this.screen?.id !== id || this.screenAt !== at || this.screen.state !== "loading") return;
      this.screen = { id, state: "error", lines: [], error: "Screen unavailable: the terminal didn't answer." };
      cx.notify();
    });
    cx.notify();
  }

  /** Goes to the card's terminal.
   * @param {Node} node */
  focus(node) {
    run(node.kind === "tool" ? "pane.focus" : "agent.focus", { terminal: node.address });
  }

  /** A peek opens over the work area; the fleet stays under it.
   * @param {Node} node */
  peek(node) {
    run("terminal.peek", { terminal: node.address });
  }

  /** @param {Node} node @param {Cx} cx */
  keep(node, cx) {
    run("terminal.keep", { terminal: node.address });
    this.note = { text: "Kept: it gets a pane in its parent's tab.", error: false };
    cx.notify();
  }

  /** @param {Cx} cx */
  send(cx) {
    const address = this.detailNode?.address, text = this.answer.value().trim();
    if (!address || !text || this.sending) return;
    this.sending = true;
    this.note = null;
    cx.notify();
    cx.spawn(async (cx) => {
      const r = await hcSafe(["send", address, text]);
      this.sending = false;
      if (r.code === 0) this.answer.set_value("");
      this.note = r.code === 0 ? { text: "Sent.", error: false } : { text: r.stderr.trim() || `hc send exited ${r.code}`, error: true };
      cx.notify();
    });
  }

  /** Keys while the answer field has the keyboard are its own, but Esc hands the keyboard back.
   * @param {KeyEvent} e @param {Cx} cx */
  onKey(e, cx) {
    if (this.typing) {
      if (e.key !== "escape") return;
      this.keys.focus();
    } else if (!this.walk(e.key, cx)) return;
    cx.stop_propagation();
    cx.notify();
  }

  /**
   * Up/down walk the picked agent's tree; Enter opens a card's detail (with the answer field, for one that needs
   * you), and on a card whose detail shows, it focuses that terminal. Left and Esc close the detail (back to the
   * tree). Agents change in the rail (agent.next / agent.prev). Answers
   * whether the key was one of these.
   * @param {string} key @param {Cx} cx
   */
  walk(key, cx) {
    if (key === "escape") {
      if (!this.detail) return false;
      this.detail = null;
      return true;
    }
    if (key === "left") { this.detail = null; return true; }
    if (!["up", "down", "enter"].includes(key)) return false;
    const { kids, byId } = this.nav;
    const at = this.cursor && kids.includes(this.cursor) ? this.cursor : null;
    if (key === "up" || key === "down") {
      const i = at ? kids.indexOf(at) : -1;
      this.cursor = kids[Math.max(0, Math.min(kids.length - 1, i + (key === "down" ? 1 : -1)))] ?? null;
      return true;
    }
    const node = at ? byId.get(at) : undefined;
    if (!node) return true;
    if (this.detail === at && node.address && node.live) this.focus(node);
    else this.openDetail(node, cx, node.status === "blocked");
    return true;
  }

  /**
   * The header's word on beads: bd's error, or no orchestrator having an epic at all.
   * @returns {string | null}
   */
  beadsWarning() {
    if (this.mode !== "live") return null;
    if (this.live.error) return `Beads: ${this.live.error}`;
    const byOrch = this.live.byOrch;
    if (!byOrch) return null;
    // One orchestrator without an epic is ordinary, and its open card says so; none of them having one means the
    // database is empty or not the one the agents write.
    const asked = [...byOrch.keys()];
    return asked.length > 1 && asked.every((a) => !(byOrch.get(a) ?? []).length)
      ? "Beads: no orchestrator has an epic — database empty or not the agents' one" : null;
  }

  /** @param {Cx} cx */
  render(cx) {
    const t = palette(), now = Date.now();
    /** @type {import("./model.js").Beads} */
    const beads = this.mode === "fixture"
      ? { mode: "fixture", epics: fixtureEpics(this.fixtureAt) }
      : { mode: "live", byOrch: this.live.byOrch ?? new Map() };
    const fleet = buildFleet({ agents: agents(), terminals: coreTerminals(), spaces: spaces(), beads });
    const roots = fleet.roots;
    const byId = new Map(roots.flatMap((r) => [r.node, ...descendants(r.node)]).map((n) => [n.id, n]));
    // The focused agent: focused().agent, or the root above it when that's one of its sub-agents; else (a shell has
    // the focus) the one shown before.
    const fa = focused()?.agent ?? null;
    const sel = roots.find((r) => r.node.address === fa)
      ?? roots.find((r) => descendants(r.node).some((n) => n.address === fa))
      ?? roots.find((r) => r.node.address === this.selAddr) ?? null;
    const selAddr = sel?.node.address ?? null;
    if (selAddr !== this.selAddr) { this.selAddr = selAddr; this.detail = null; this.cursor = null; }
    const kids = sel ? descendants(sel.node).map((n) => n.id) : [];
    const shown = this.detail && kids.includes(this.detail) ? byId.get(this.detail) ?? null : null;
    this.detailNode = shown;
    this.nav = { kids, byId };
    // Showing anew, refresh live beads.
    const visible = this.isShown() && !checking();
    if (visible && !this.wasShown && this.mode === "live") cx.timer.after(0, (cx) => this.loadBeads(cx));
    this.wasShown = visible;

    // Cards fill the panel, less the spine's indent for the tree's depth: a wider panel gets wider cards.
    const depth = sel ? Math.max(1, depthOf(sel.node)) : 1;
    const child = Math.max(200, Math.min(440, this.width - 40 - ARM - (depth - 1) * (16 + ARM)));
    /** @type {Ui} */
    const ui = { t, now, size: { child } };
    const tree = () => v_flex().id("fleet-body").flex_1().h_full().min_w(0).overflow_y_scrollbar().px(16).pt(14).pb(24)
      .when(!roots.length, (b) => b.child(this.empty(t)))
      .when(roots.length > 0 && !sel, (b) => b.child(div().text_size(SM).line_height("18px").text_color(t.muted)
        .child("Pick an agent in the sidebar, or focus its pane, to see its workers and tasks here.")))
      .when(Boolean(sel) && !kids.length, (b) => b.child(div().text_size(SM).text_color(t.muted).child("No workers or beads")))
      .when(Boolean(sel && kids.length), (b) => (sel ? b.child(this.branch(ui, sel.node.children, "top")) : b));

    return v_flex().id("fleet").track_focus(this.keys).on_key_down((e, cx) => this.onKey(e, cx))
      .on_size_change((sz, cx) => { if (Math.abs(sz.width - this.width) > 1) { this.width = sz.width; cx.notify(); } })
      .size_full().min_w(0).bg(t.canvas).text_color(t.foreground).text_size(MD)
      .when(Boolean(shown), (el) => (shown ? el.child(this.detailPanel(ui, shown, true).flex_1().min_h(0)) : el))
      .when(!shown, (el) => el.child(this.header(ui, sel, this.beadsWarning())).child(tree()).child(this.footer(t)));
  }

  /** The picked agent: its tile, name, state and where it runs; under it, its tree's rollup and what's off about its
   * beads, whether beads are a sample or being read, and the fleet's beads warning.
   * @param {Ui} ui @param {ShownRoot | null} sel @param {string | null} warning */
  header(ui, sel, warning) {
    const { t, now } = ui;
    const n = sel?.node;
    const reading = this.mode === "live" && !this.live.byOrch && !this.live.error;
    const meta = n ? [n.app, n.address, sel?.space, ageLabel(n, now)].filter((x, i, all) => x && all.indexOf(x) === i).join(" · ") : "";
    // Said once for the tree, not on every card: workers no bead names, or an orchestrator with no epic.
    const r = sel?.rollup;
    const noEpic = this.mode === "live" && sel?.orch && n?.address && this.live.byOrch?.get(n.address)?.length === 0;
    const note = r?.unbeaded ? `${r.unbeaded} ${r.unbeaded === 1 ? "worker has" : "workers have"} no bead`
      : noEpic ? "No open epic for this session" : null;
    const mark = !r ? "idle" : r.needs ? "blocked" : r.failed ? "failed" : r.working ? "running" : "idle";
    const top = h_flex().pt(14).pb(10).gap(10).items_start()
      .when(Boolean(n), (el) => (n ? el.child(this.tile(t, n, 28)) : el))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(h_flex().gap(8).items_center()
          .child(div().min_w(0).truncate().text_size(LG).font_semibold().child(n?.name ?? "Agents"))
          .when(Boolean(n), (el) => (n ? el.child(this.badge(t, n)) : el)))
        .child(div().text_size(XS).text_color(t.muted).truncate().child(meta)));
    const status = h_flex().pb(12).gap(8).items_center().text_size(XS).text_color(t.muted)
      .when(Boolean(r), (el) => el.child(this.glyph(mark, this.color(t, mark === "running" ? "working" : mark === "idle" ? "ended" : mark))))
      .child(div().flex_none().text_color(r?.needs ? t.foreground : t.muted).child(r?.text ?? ""))
      .when(Boolean(note), (el) => el.child(div().text_color(t.dim).child("·")).child(div().min_w(0).truncate().child(note ?? "")))
      .child(div().flex_1())
      .when(this.mode === "fixture", (el) => el.child(div().id("sample-chip").h(20).px(7).flex().flex_none().items_center().rounded(5)
        .border_1().border_color(t.input).bg(t.raised).font_medium().text_color(t.foreground)
        .tooltip("Beads here are a made-up sample (fleet.live for real ones)").child("Sample data")))
      .when(reading, (el) => el.child(div().flex_none().child("Reading beads…")))
      .when(Boolean(warning), (el) => el.child(h_flex().id("beads-warning").min_w(0).gap(6).items_center()
        .text_color(t.blocked).tooltip(warning ?? "")
        .child(svg(`${ME}/alert.svg`).size(12).flex_none().text_color(t.blocked))
        .child(div().min_w(0).truncate().child(warning ?? ""))));
    return v_flex().id("fleet-header").flex_none().px(16).border_b_1().border_color(t.border).bg(t.chrome)
      .child(top).when(Boolean(n), (el) => el.child(status));
  }

  /** The keys, and which beads database the live view reads. @param {Palette} t */
  footer(t) {
    return h_flex().id("fleet-footer").h(30).flex_none().px(20).gap(16).items_center().border_t_1().border_color(t.border)
      .bg(t.chrome).text_size(XS).text_color(t.muted)
      .child(div().flex_none().child("↑↓ Enter · Alt+↑↓ agents"))
      .child(div().flex_1())
      .when(this.mode === "live" && Boolean(this.beadsDir), (el) => el.child(div().min_w(0).truncate()
        .child(`beads ${(this.beadsDir ?? "").replace(/^\/Users\/[^/]+|^\/home\/[^/]+/, "~")}`)));
  }

  /** @param {Palette} t */
  empty(t) {
    return v_flex().id("fleet-empty").max_w(460).mt(48).mx_auto().gap(10).items_center().text_center()
      .child(div().text_size(LG).font_semibold().child("No agents are reporting yet"))
      .child(div().text_size(MD).line_height("20px").text_color(t.muted)
        .child("Agents show up here once they report a status. Start one from the + menu in the tab bar, or from any terminal:"))
      .child(div().px(10).py(5).rounded(6).bg(t.background).border_1().border_color(t.border)
        .font_family(String(settings()?.font ?? "JetBrains Mono")).text_size(SM).child("hc run -- claude"));
  }

  /**
   * Children down a spine: each row an arm into its card, the spine running on past all but the last, which
   * turns into its card on a rounded elbow. "side": the first row's arm continues the root's stub; "top": the
   * spine drops from the card above. A child's own children hang under it the same way, from the top.
   * @param {Ui} ui @param {Node[]} nodes @param {"side" | "top"} entry
   * @returns {ReturnType<typeof v_flex>}
   */
  branch(ui, nodes, entry) {
    const line = ui.t.accent;
    return v_flex().children(nodes.map((n, i) => {
      const first = i === 0, last = i === nodes.length - 1;
      const pad = first && entry === "side" ? 0 : GAP;
      const y = pad + ANCHOR;
      const above = !first || entry === "top";
      const arm = div().relative().w(ARM).flex_none().self_stretch()
        .when(above && last, (el) => el.child(div().absolute().top(0).left(0).w(ARM).h(y + 1)
          .border_l_1().border_b_1().rounded_bl(7).border_color(line)))
        .when(above && !last, (el) => el.child(div().absolute().top(0).left(0).w(1).h(y).bg(line)))
        .when(!(above && last), (el) => el.child(div().absolute().top(y).left(0).w(ARM).h(1).bg(line)))
        .when(!last, (el) => el.child(div().absolute().top(y).left(0).bottom(0).w(1).bg(line)));
      return h_flex().items_start().child(arm)
        .child(v_flex().pt(pad).items_start()
          .child(this.card(ui, n))
          .when(n.children.length > 0, (el) => el.child(div().pl(16).child(this.branch(ui, n.children, "top")))));
    }));
  }

  /** A state as a mark that reads without its color. @param {string} state @param {Color} color */
  glyph(state, color) {
    if (state === "running") return svg("mods/workspace-chrome/spinner.svg").size(11).flex_none().text_color(color).spin(900);
    if (state === "blocked") return svg(`${ME}/alert.svg`).size(11).flex_none().text_color(color);
    if (state === "failed") return svg(`${ME}/failed.svg`).size(11).flex_none().text_color(color);
    if (state === "queued") return svg(`${ME}/queued.svg`).size(11).flex_none().text_color(color);
    if (state === "working" || state === "done") return div().size(7).mx(2).flex_none().rounded_full().bg(color);
    return div().size(8).mx(1.5).flex_none().rounded_full().border_1().border_color(color);
  }

  /** @param {Palette} t @param {string} state @returns {Color} */
  color(t, state) {
    /** @type {Record<string, Color>} */
    const by = {
      working: t.working, supervising: t.working, running: t.working, blocked: t.blocked, done: t.done, idle: t.idle,
      failed: t.ansi1 ?? t.blocked, queued: t.muted, ended: t.muted, sample: t.muted,
    };
    return by[state] ?? t.unknown;
  }

  /** Needing the person and failing are the only filled badges; every other state is a quiet mark and word.
   * @param {Palette} t @param {Node} n */
  badge(t, n) {
    const state = n.kind === "ended" ? "ended" : n.kind === "synthetic" ? "sample"
      : n.kind === "tool" && n.status === "working" ? "running" : n.shown;
    const c = this.color(t, state);
    const loud = state === "blocked" || state === "failed";
    return h_flex().h(20).gap(5).flex_none().items_center().text_size(XS)
      .when(loud, (el) => el.px(6).rounded(5).bg(tint(c)).font_medium().text_color(c))
      .when(!loud, (el) => el.text_color(t.muted))
      .child(this.glyph(state, c)).child(LABEL[state] ?? state);
  }

  /** The program's icon on a tile; a task glyph for a bead, a terminal glyph otherwise. @param {Palette} t @param {Node} n */
  tile(t, n, size = 24) {
    const p = n.program;
    const ink = p?.color && isColor(p.color) ? p.color : t.foreground;
    const pic = !p?.icon ? svg(n.kind === "bead" ? `${ME}/task.svg` : "mods/workspace-chrome/terminal.svg").size(13).text_color(t.muted)
      : p.tint ? svg(p.icon).size(14).text_color(ink) : image(p.icon).w(14).h(14);
    return div().size(size).flex_none().flex().items_center().justify_center().rounded(6)
      .bg(p?.tint && p.tile && isColor(p.tile) ? p.tile : t.raised).child(pic);
  }

  /**
   * The lifecycle strip: six segments, those passed in a quiet ink, the current one in the card's state color;
   * under it the current step (or what blocks it) and the PR. Wide (the detail) labels every step.
   * @param {Palette} t @param {Node} n @param {import("./model.js").Life} life @param {boolean} wide
   */
  strip(t, n, life, wide) {
    const c = life.blocked ? t.blocked : n.status === "queued" ? t.muted : n.status === "idle" ? t.foreground : this.color(t, n.status);
    const pr = prNumber(life.pr);
    const caption = life.blocked ? `Blocked · ${life.blocked}`
      : life.step >= 3 && life.round ? `${STEPS[life.step]} · review r${life.round}` : stepLabel(life, life.step);
    return v_flex().gap(5)
      .child(h_flex().gap(3).children(STEPS.map((_s, i) => v_flex().flex_1().gap(4)
        .child(div().h(4).rounded(2).bg(i < life.step ? t.muted : i === life.step ? c : t.input))
        .when(wide, (el) => el.child(div().text_size(XS).truncate()
          .text_color(i === life.step ? t.foreground : t.muted).child(stepLabel(life, i)))))))
      .when(!wide, (el) => el.child(h_flex().gap(8).items_center().text_size(XS)
        .child(div().flex_1().min_w(0).truncate().text_color(life.blocked ? t.blocked : t.muted).child(caption))
        .when(Boolean(pr), (r) => r.child(div().flex_none().text_color(t.muted).child(`PR #${pr}`)))));
  }

  /** A card in the tree: a sub-agent, tool or task. @param {Ui} ui @param {Node} n */
  card(ui, n) {
    const { t, now } = ui;
    const cursor = this.cursor === n.id, shown = this.detail === n.id;
    const since = ageLabel(n, now);
    const meta = (n.bead ? [n.bead.id, n.address] : [n.app, n.address]).filter((x, i, all) => x && all.indexOf(x) === i).join(" · ");
    const kids = n.children.length;
    const answer = n.status === "blocked" && answerable(n);
    return v_flex().id(`card-${n.id}`).w(ui.size.child).flex_none().px(12).pt(11).pb(10).gap(7).rounded(12)
      .bg(shown ? t.selected : t.background).border_1().border_color(cursor ? t.accent : t.border)
      .when(n.status === "queued", (el) => el.border_dashed())
      .cursor_pointer().hover((s) => s.border_color(cursor ? t.accent : t.input))
      .role("button").accessibility_label(`${n.name}, ${LABEL[n.shown] ?? n.shown}`)
      .on_click((_e, cx) => {
        this.cursor = n.id;
        this.keys.focus();
        // Again on the card whose detail shows: go to its terminal.
        if (this.detail === n.id && n.live && n.address) this.focus(n); else this.openDetail(n, cx);
      })
      .child(h_flex().gap(9).items_start()
        .child(this.tile(t, n))
        .child(v_flex().flex_1().min_w(0).gap(1)
          .child(h_flex().gap(8).items_center()
            .child(div().flex_1().min_w(0).text_size(MD).font_medium().truncate().child(n.name))
            .child(this.badge(t, n)))
          .child(h_flex().gap(8).text_size(XS).text_color(t.muted)
            .child(div().flex_1().min_w(0).truncate().child(meta))
            .when(Boolean(since), (m) => m.child(div().flex_none().child(since ?? ""))))))
      .when(Boolean(n.task), (el) => el.child(div().text_size(SM).text_color(t.muted).truncate().child(n.task)))
      .when(Boolean(n.life), (el) => (n.life ? el.child(this.strip(t, n, n.life, false)) : el))
      .when(kids > 0 || answer, (el) => el.child(h_flex().gap(8).items_center().text_size(XS)
        .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(kids ? `${kids} under it` : ""))
        .when(answer, (f) => f.child(div().id(`answer-${n.id}`).h(22).px(8).flex().items_center().rounded(5)
          .border_1().border_color(t.input).bg(t.raised).text_color(t.foreground).font_medium()
          .hover((s) => s.bg(t.hover)).role("button").accessibility_label(`Answer ${n.name}`)
          .on_click((_e, cx) => { cx.stop_propagation(); this.openDetail(n, cx, true); })
          .child("Answer")))));
  }

  /** @param {Palette} t @param {string} id @param {string} label
   * @param {{ primary?: boolean, enabled?: boolean, onClick: (cx: Cx) => void }} opts */
  button(t, id, label, { primary = false, enabled = true, onClick }) {
    return div().id(id).h(28).px(12).flex().items_center().rounded(6).border_1().text_size(SM).font_medium()
      .border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground)
      .role("button").accessibility_label(label)
      .when(!enabled, (el) => el.opacity(0.4))
      .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.86)).on_click((_e, cx) => onClick(cx)))
      .child(label);
  }

  /** @param {Palette} t @param {string} title @param {string | null} aside */
  section(t, title, aside) {
    return h_flex().gap(8).items_center().text_size(SM)
      .child(div().font_medium().text_color(t.muted).child(title))
      .when(Boolean(aside), (el) => el.child(div().text_size(XS).text_color(t.muted).child(aside ?? "")))
      .child(div().flex_1().h(1).bg(t.border));
  }

  /** A label and its value, as the detail lists them. @param {Palette} t @param {string} label @param {string} value @param {Color} [ink] */
  row(t, label, value, ink) {
    return h_flex().gap(8).items_start().text_size(SM)
      .child(div().w(60).flex_none().text_color(t.muted).child(label))
      .child(div().flex_1().min_w(0).line_height("18px").text_color(ink ?? t.foreground).child(value));
  }

  /** One bead event: what happened and its few facts on one line, the body's first line under it; a click shows
   * the body's first lines. The newest reads strongest.
   * @param {Palette} t @param {BeadEvent} e @param {number} i @param {number} now */
  event(t, e, i, now) {
    const open = this.expanded.has(i), facts = eventFacts(e), line = e.body ? firstLine(e.body) : "";
    return v_flex().id(`ev-${i}`).gap(2).px(8).py(6).mx(-8).rounded(6)
      .when(Boolean(e.body), (el) => el.cursor_pointer().hover((st) => st.bg(t.hover))
        .on_click((_e, cx) => { if (open) this.expanded.delete(i); else this.expanded.add(i); cx.notify(); }))
      .child(h_flex().gap(8).items_center().text_size(SM)
        .child(div().flex_none().font_medium().text_color(i === 0 ? t.foreground : t.muted).child(eventName(e)))
        .child(div().flex_1().min_w(0).truncate().text_size(XS).text_color(t.muted).child(facts))
        .child(div().flex_none().text_size(XS).text_color(t.muted).child(e.at ? `${age(e.at, now)} ago` : "")))
      .when(Boolean(line) && !open, (el) => el.child(div().text_size(SM).text_color(t.muted).truncate().child(line)))
      .when(open, (el) => el.child(div().text_size(SM).line_height("18px").text_color(t.muted).child(brief(e.body))));
  }

  /** The detail: beside the tree, or (`replace`, narrow) in its place with a way back.
   * @param {Ui} ui @param {Node} n @param {boolean} replace */
  detailPanel(ui, n, replace) {
    const { t, now } = ui;
    const terminal = Boolean(n.address && n.live && (n.kind === "agent" || n.kind === "tool"));
    const life = n.life, pr = life?.pr;
    const mono = String(settings()?.font ?? "JetBrains Mono");
    const sc = this.screen?.id === n.id ? this.screen : null;
    const meta = [n.bead?.id, n.app, n.address, n.tab, ageLabel(n, now)].filter((x, i, all) => x && all.indexOf(x) === i).join(" · ");
    const note = this.note;
    const all = [...n.events].reverse(), events = this.allEvents ? all : all.slice(0, EVENTS);
    /** @param {Cx} cx */
    const back = (cx) => { this.detail = null; cx.notify(); };
    return v_flex().id("fleet-detail").flex_none().min_h(0).bg(t.popover).border_color(t.border)
      .when(replace, (el) => el.child(h_flex().h(36).flex_none().px(10).items_center().border_b_1().border_color(t.border)
        .child(h_flex().id("detail-back").h(26).px(6).gap(4).items_center().rounded(5).cursor_pointer()
          .role("button").accessibility_label("Back to the tree").text_size(SM).text_color(t.muted)
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => back(cx))
          .child(svg("mods/workspace-chrome/chevron-left.svg").size(14)).child("Back"))))
      .child(h_flex().px(16).pt(14).pb(12).gap(10).items_start().border_b_1().border_color(t.border)
        .child(this.tile(t, n, 28))
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(div().text_size(LG).font_semibold().truncate().child(n.name))
          .child(div().text_size(XS).text_color(t.muted).truncate().child(meta)))
        .child(this.badge(t, n))
        .when(!replace, (el) => el.child(div().id("detail-close").size(24).flex_none().flex().items_center().justify_center().rounded(5)
          .cursor_pointer().role("button").accessibility_label("Close detail").text_color(t.muted)
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => back(cx))
          .child(svg("mods/workspace-chrome/x.svg").size(13)))))
      .child(v_flex().id("detail-body").flex_1().min_h(0).min_w(0).overflow_y_scrollbar().px(16).pt(14).pb(18).gap(16)
        .when(Boolean(n.task), (el) => el.child(div().text_size(MD).line_height("20px").text_color(t.foreground).child(n.task)))
        .when(Boolean(life), (el) => (!life ? el : el.child(this.strip(t, n, life, true))))
        .when(Boolean((n.report && n.report !== n.task) || pr || life?.blocked), (el) => el.child(v_flex().gap(6)
          .when(Boolean(n.report && n.report !== n.task), (b) => b.child(this.row(t, "Report", n.report)))
          .when(Boolean(pr), (b) => b.child(this.row(t, "PR", pr ?? "")))
          .when(Boolean(life?.blocked), (b) => b.child(this.row(t, "Blocked", life?.blocked ?? "", t.blocked)))))
        // Without a live terminal there's nothing to focus, peek at or answer: say so once instead.
        .when(!terminal, (el) => el.child(div().text_size(SM).text_color(t.muted)
          .child(n.kind === "bead" && !n.events.some((e) => e.name === "dispatched") ? "No terminal yet." : "Its terminal has ended.")))
        .when(terminal, (el) => el.child(h_flex().gap(8).flex_wrap()
          .child(this.button(t, "act-focus", "Focus", { primary: true, onClick: () => this.focus(n) }))
          .child(this.button(t, "act-peek", "Peek", { onClick: () => this.peek(n) }))
          .when(!n.pane, (b) => b.child(this.button(t, "act-keep", "Keep", { onClick: (cx) => this.keep(n, cx) })))))
        .when(answerable(n), (el) => el.child(v_flex().gap(6)
          .child(h_flex().gap(8)
            .child(Input.new(this.answer).flex_1().h(30).px(10).rounded(6).border_1()
              .border_color(this.typing ? t.accent : t.input).bg(t.background).text_size(MD).text_color(t.foreground))
            .child(this.button(t, "act-send", this.sending ? "Sending…" : "Send", { enabled: !this.sending, onClick: (cx) => this.send(cx) })))
          .when(n.status === "blocked", (b) => b.child(div().text_size(XS).text_color(t.muted)
            .child("Sends with Enter. A program holding a dialog may refuse typed text.")))))
        .when(Boolean(note), (el) => el.child(div().text_size(SM).text_color(note?.error ? t.blocked : t.muted).child(note?.text ?? "")))
        .child(v_flex().gap(4)
          .child(div().pb(4).child(this.section(t, "Bead events", n.bead ? `${n.bead.id} · ${this.mode === "fixture" ? "sample" : "live"}` : null)))
          .when(events.length === 0, (el) => el.child(div().text_size(SM).text_color(t.muted)
            .child(n.bead ? "No events on this bead yet." : this.mode === "live" && this.live.error ? "Beads unavailable." : "No bead names this terminal.")))
          .children(events.map((e, i) => this.event(t, e, i, now)))
          .when(all.length > EVENTS, (el) => el.child(div().id("ev-more").pt(2).text_size(XS).text_color(t.muted).cursor_pointer()
            .role("button").hover((st) => st.text_color(t.foreground))
            .on_click((_e, cx) => { this.allEvents = !this.allEvents; cx.notify(); })
            .child(this.allEvents ? "Show fewer" : `Show all ${all.length}`))))
        .when(terminal, (el) => el.child(v_flex().w_full().min_w(0).gap(8)
          .child(this.section(t, "Screen", sc?.state === "ready" ? `last ${sc.lines.length} lines` : null))
          .child(v_flex().id("screen").w_full().min_w(0).flex_none().h(Math.max(4, sc?.lines.length ?? 0) * LINE + 26).py(12).px(12).rounded(8)
            .bg(t.background).border_1().border_color(t.border)
            .font_family(mono).text_size(SM).line_height(`${LINE}px`)
            .when(sc?.state === "loading", (el) => el.gap(8).children([0.9, 0.7, 0.8, 0.45].map((w, i) => div().id(`sk-${i}`).h(10).w(Math.round(w * 340)).rounded(3).bg(t.raised)
              .loop("opacity", { from: 0.5, to: 1, period: 1100 }))))
            .when(sc?.state === "error", (el) => el.gap(8).items_start().text_color(t.muted)
              .child(div().child(sc?.error ?? ""))
              .child(this.button(t, "screen-retry", "Retry", { onClick: (cx) => this.readScreen(n, cx) })))
            .when(sc?.state === "ready", (el) => el.text_color(t.foreground)
              .children((sc?.lines.length ? sc.lines : [" "]).map((l, i) => div().id(`ln-${i}`).w_full().whitespace_nowrap().truncate().child(l || " "))))))));
  }
}
