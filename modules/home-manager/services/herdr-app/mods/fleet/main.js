// Agents panel: herdr-panda's right panel (`panel-body` child `fleet`), following the focused agent (the one picked in
// the rail, or the focused pane's). An orchestrator draws its session: a header (state, mode, slots, source ticket,
// progress), then its tasks down a spine, each with its worker, review rounds, PR, a labeled strip and whose turn it
// is. Any other agent draws the terminal tree of what it started; an agent with nothing under it, its own report.
// A card opens a detail: your question and answer field, links, sessions and the task's timeline, beside the tree from
// 640 px, else in its place with a way back. Session rows reach a live agent one way: Peek for one with no pane (a
// hidden worker or reviewer), Focus for one whose pane is on another tab, nothing for one already on screen.
//
// Data: shared bd.js loadSession for the drawn orchestrator only (its newest open epic), on show and every 10 s while
// shown and the window is visible. Names (name.js), ages (clock.js), words (words.js), tasks (tasks.js) are the rail's
// own, so both agree. An answer is checked against the bead's live hold (bd.js liveHold) when it is sent.
// Keys: fleet.focus gives the panel the keyboard; ↑↓ move between cards (also inside the detail), Enter opens, Esc and ←
// close; in a detail, a puts the keyboard in the answer field, f focuses or p peeks at the worker, r revives it, o opens
// the PR. Shared "fleet.open" ({ orch, epic, bead, at }) draws that orchestrator and opens the task, whatever is focused.
// fleet.fixture / fleet.live switch sample and live data.
// Motion is native: pulses along the spine and a card's flash (.transition), "Your turn" chips (.loop). Timers are for
// data and for ending a pulse, never for animation.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, ScrollHandle } from "gpui-base";
import {
  agents, terminals, spaces, panes, settings, run, hc, exec, checking, window, nextCommand, layout, focused, shared, setShared, notify,
} from "herdr";
import { namer, termName } from "./name.js";
import { agentWord, took, ago, turnWord, reasonWord } from "./words.js";
import { Clock } from "./clock.js";
import { sourceLabel } from "./tasks.js";
import { beadsDir, loadSession, liveHold, statusMs } from "./bd.js";
import { revive } from "./revive.js";
import {
  buildRoots, descendants, isSolo, sessionView, slotsOf, prFor, prNumber, newestLine, timelineOf, pulsesOf,
  answerState, answerMessage, reachOf,
} from "./model.js";
import { fixtureSession, fixtureTerms, fixtureHibernated } from "./fixtures.js";
import { timelineView } from "./timeline.js";
import {
  META, BODY, NAME, ME, palette, tint, mono, agentColor, turnColor, glyph, tile, badge, keyChip, turnChip, prChip, button,
  section, strip, ciMark,
} from "./ui.js";

const POLL = 10000;
const PANEL = "panel", BODY_ID = "panel-body", SELF = "fleet";
const HIBERNATED = "panda-focus.hibernated";
// The detail sits beside the tree from this width; the tree is then TREE px wide.
const SIDE_AT = 640, TREE = 340;
// The spine's gutter in a task row, and where a node sits on it (its center, from the row's top).
const GUTTER = 26, NODE_Y = 20;
// A task detail's timeline fills what its fixed part leaves; under this height the whole detail scrolls instead.
const TIMELINE_MIN = 200, DETAIL_BAR = 40, DETAIL_PAD = 14 + 14 + 20;
// The panel's default width, until its first size arrives.
const START_W = 368;
// How long a fleet.open request waits for its orchestrator's session to load (ms).
const OPEN_WAIT = 20000;
// A pulse: how long its dot and flash live (the flash fades over 1.2 s), and the beat before its target is set.
const PULSE_LIFE = 1400, PULSE_BEAT = 50;
// Terminal tree connectors: the stub from a root to its spine, each child's arm, and where a line meets a card.
const ARM = 22, ANCHOR = 23, GAP = 10;

const hcSafe = (args) => hc(args).catch((e) => ({ code: 1, stdout: "", stderr: e instanceof Error ? e.message : String(e) }));
const firstLine = (s) => (s ?? "").split("\n").find((l) => l.trim())?.trim() ?? "";

// A layout node by id, in layout()'s tree (clicks included: a selected stack child is its `active`).
function findNode(node, id) {
  if (!node || typeof node !== "object") return null;
  if (node.id === id) return node;
  for (const c of Array.isArray(node.children) ? node.children : []) { const f = findNode(c, id); if (f) return f; }
  return null;
}

// "Review r1 · closed"; parallel reviewers of one round each name themselves ("Review r1 · r-abc-codex · closed").
const reviewLabel = (task, r) => {
  const twin = task.reviewers.some((o) => o !== r && o.round === r.round);
  return `Review r${r.round}${twin ? ` · ${r.bead.assignee ?? r.bead.id}` : ""} · ${r.bead.status ?? "open"}`;
};

const coreTerminals = () => terminals().flatMap((k) => (typeof k.address === "string" ? [k] : []));

const SAMPLE_ROOT = () => ({
  address: "tfx0", space: "sample", orch: true,
  node: { id: "tfx0", address: "tfx0", kind: "agent", name: "[o] sample session", program: null, app: "sample", status: "working",
    shown: "working", report: "", live: true, pane: false, tab: null, labels: {}, children: [] },
});

// A finished worker comes back as its own launch made it (shared revive.js); its row goes once the new one started.
async function reviveRow(r) {
  const parentLive = (a) => terminals().some((k) => k.address === a && k.state === "live");
  const res = await revive(r.address, { hc, exec, parentLive });
  if (!res.ok) {
    notify({ title: "Couldn't revive the agent", body: `${r.title ?? r.name ?? r.address}: ${res.error}`, level: "error" });
    return;
  }
  setShared(HIBERNATED, (shared(HIBERNATED) ?? []).filter((x) => x.address !== r.address));
  if (res.warning) notify({ title: "Revived; the old terminal stayed", body: res.warning, level: "warning" });
}

export default class Fleet extends View {
  init(_props, cx) {
    // "fixture": the sample session instead of live beads.
    this.mode = "live";
    this.fixtureAt = Date.now();
    this.wasShown = false;
    // Live sessions by orchestrator address: { session, extra, error, at }; the last answer is kept while one runs.
    this.data = new Map();
    // Addresses being read now, and the one last asked for on show.
    this.loading = new Set();
    this.askedFor = null;
    this.beadsDir = null;
    this.orchAddr = null;
    // The agent shown, as last seen: picking another one closes the detail.
    this.selAddr = null;
    this.cursor = null;
    this.openId = null;
    this.nav = { ids: [] };
    this.width = START_W;
    // The task detail's height and its fixed part's (window px, from on_size_change; 0 until laid out).
    this.detailH = 0;
    this.fixedH = 0;
    this.note = null;
    this.sending = false;
    this.typing = false;
    // What the last render drew, for Send and the detail's keys: { task, route, node, answerable, ... }.
    this.shownDetail = null;
    // The question the answer field answers ({ taskId, qid }), set when its block draws.
    this.asking = null;
    this.askedNow = null;
    // A fleet.open's orchestrator drawn whatever is focused, until the focus moves to another agent.
    this.pin = null;
    this.reviving = new Set();
    // Timeline view state: filter, rounds opened or folded by hand, events expanded (keyed by time and index).
    this.tl = { filter: "all", rounds: new Map(), ev: new Set(), last: -1 };
    this.tlJump = false;
    this.tlCount = 0;
    this.tlScroll = ScrollHandle.new();
    this.treeScroll = ScrollHandle.new();
    // Pulses live: key -> { key, taskId, born, down, tone, kind }; seen keeps a finished one from starting again.
    this.pulses = new Map();
    this.pulseSeen = new Map();
    this.fleetOpenAt = 0;
    this.pendingOpen = null;
    this.clock = new Clock((address) => this.fetchMs(address));
    this.keys = cx.focus_handle();
    this.answer = InputState.new({ placeholder: "Your answer…" });
    this.answer.on("submit", (_e, cx) => this.submit(cx));
    // A draft belongs to the question on screen while it is typed: editing it binds it to that question.
    this.answer.on("change", () => { this.asking = this.askedNow ?? null; });
    this.answer.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.answer.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    if (checking()) return;
    // A hidden copy keeps running (the stack's other child, another tab): poll only while this one shows.
    cx.timer.every(POLL, (cx) => {
      if (this.mode === "live" && window()?.visible && this.isShown() && this.orchAddr) this.loadSession(cx, this.orchAddr);
    });
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "fixture" || c === "live") this.setMode(c, cx);
        else if (c === "focus") {
          // The ring needs a card: the first that wants you, else the first.
          if (!this.cursor || !this.nav.ids.includes(this.cursor)) this.cursor = [...(this.nav.you ?? [])][0] ?? this.nav.ids[0] ?? null;
          this.keys.focus();
          cx.notify();
        }
        else if (this.walk(c, cx)) cx.notify();
      }
    });
  }

  // The core's status time for the clock's first sight of a terminal. Sample terminals aren't real ones.
  fetchMs(address) {
    if (checking() || String(address).startsWith("tfx")) return Promise.resolve(null);
    return statusMs(address).catch(() => null);
  }

  // Whether the right panel shows, with this block picked.
  isShown() {
    const root = layout(), body = findNode(root, BODY_ID);
    const active = body?.active ?? (Array.isArray(body?.children) ? body.children[0]?.id : null);
    return findNode(root, PANEL)?.hidden !== true && active === SELF;
  }

  // The drawn orchestrator's newest open epic and its tasks, with the login shell's BEADS_DIR (older open epics are
  // only counted). On failure the cards keep what they had and the header says why. One read per address at a time.
  // Called from timers and tasks only, never from render.
  loadSession(cx, address) {
    if (this.loading.has(address) || checking()) return;
    this.loading.add(address);
    if (!this.data.has(address)) cx.notify();
    const startedAt = Date.now();
    cx.spawn(async (cx) => {
      const before = this.data.get(address);
      try {
        if (this.beadsDir === null) this.beadsDir = await beadsDir();
        const { session, extra } = await loadSession(address, this.beadsDir);
        this.data.set(address, { session, extra, error: null, at: Date.now(), startedAt });
      } catch (e) {
        this.data.set(address, { session: before?.session ?? null, extra: before?.extra ?? 0, at: before?.at ?? 0,
          error: e instanceof Error ? e.message : String(e) });
      }
      this.loading.delete(address);
      cx.notify();
    });
  }

  setMode(mode, cx) {
    if (mode === this.mode) return;
    this.mode = mode;
    this.closeDetail();
    if (mode === "live" && this.orchAddr) this.loadSession(cx, this.orchAddr);
    cx.notify();
  }

  // ----- opening and closing ---------------------------------------------------------------------------------------

  // Closing a detail also forgets its answer: a later Send can't reach the task it was typed for.
  closeDetail() {
    this.openId = null;
    this.note = null;
    this.asking = null;
    this.answer.set_value("");
  }

  // Shows a card's detail. State only, so render may call it (render must never notify); callers in handlers notify.
  // `answer` puts the keyboard in the answer field (a handler only).
  showDetail(id, cx, answer = false) {
    const changed = this.openId !== id;
    this.openId = id;
    this.cursor = id;
    if (changed) {
      this.note = null;
      this.asking = null;
      this.answer.set_value("");
      this.tl = { filter: "all", rounds: new Map(), ev: new Set(), last: -1 };
      this.tlJump = true;
      this.tlCount = 0;
    }
    if (answer) { this.answer.focus(); cx.timer.after(60, () => this.answer.focus()); }
  }

  open(id, cx, answer = false) {
    this.showDetail(id, cx, answer);
    cx.notify();
  }

  focusTerm(address, tool = false) { run(tool ? "pane.focus" : "agent.focus", { terminal: address }); }
  peek(address) { run("terminal.peek", { terminal: address }); }

  // A PR opens in the PR panel when its feed has it (as panda-subagents' p does), else in the browser.
  openPr(pr, ref, cx) {
    if (pr) {
      setShared("pr.select", { repo: pr.repo, number: pr.number, at: Date.now() });
      run("layout.select", { stack: BODY_ID, child: "pr" });
      run("layout.show", { id: PANEL });
    } else if (/^https?:\/\//.test(ref ?? "")) cx.open_url(ref);
  }

  reviveRow(r, cx) {
    if (this.reviving.has(r.address)) return;
    this.reviving.add(r.address);
    cx.notify();
    cx.spawn(async (cx) => {
      try { await reviveRow(r); } finally { this.reviving.delete(r.address); cx.notify(); }
    });
  }

  // ----- answers ---------------------------------------------------------------------------------------------------

  // Send: the target is what the detail shows now, never one kept from an earlier render. A task's answer goes to
  // the orchestrator only while the question it answers is still the bead's live hold (read from bd now); a blocked
  // agent's goes into its own dialog (--force: hc refuses to type into a blocked program otherwise).
  submit(cx) {
    const text = this.answer.value().trim(), shown = this.shownDetail;
    if (!text || this.sending || !shown) return;
    let job;
    if (shown.kind === "task") {
      const { task, route, orch } = shown;
      const qid = task.life.holdQuestionId;
      // The draft answers the question it was typed under; a newer question needs the draft edited (or retyped) first.
      if (route !== "answer" || task.turn !== "you" || !qid || this.asking?.taskId !== task.id || this.asking.qid !== qid) {
        this.note = { text: "The question changed after you typed this. Read it, then edit your answer to send it.", error: true };
        cx.notify();
        return;
      }
      job = async () => {
        const live = await liveHold(this.beadsDir ?? "", task.id).catch((e) => ({ error: e instanceof Error ? e.message : String(e) }));
        if (live.error) return { error: `Couldn't check the question: ${live.error}` };
        if (live.hold !== "needs-user" || live.question?.id !== qid) return { error: "That question was answered or replaced. Its newest state is loading." };
        const message = answerMessage({ key: task.key, id: task.id, qid, question: live.question.text, text });
        return { r: await hcSafe(["send", "--", orch, message]), ok: "Sent to the orchestrator. It records your decision." };
      };
    } else if (shown.kind === "terminal" && shown.answerable) {
      job = async () => ({ r: await hcSafe(["send", "--force", "--", shown.node.address, text]), ok: "Sent." });
    } else return;
    this.sending = true;
    this.note = null;
    cx.notify();
    cx.spawn(async (cx) => {
      const out = await job();
      this.sending = false;
      // Clear only the draft that was sent: the field may hold another task's draft by now.
      if (out.r?.code === 0 && this.answer.value().trim() === text
        && (shown.kind !== "task" || this.openId === shown.task.id)) this.answer.set_value("");
      this.note = out.error ? { text: out.error, error: true }
        : out.r.code === 0 ? { text: out.ok, error: false }
          : { text: out.r.stderr.trim() || `hc send exited ${out.r.code}`, error: true };
      if (out.error) this.loadSession(cx, shown.orch ?? this.orchAddr);
      cx.notify();
    });
  }

  // ----- keys ------------------------------------------------------------------------------------------------------

  // Keys while the answer field has the keyboard are its own, but Esc hands the keyboard back.
  onKey(e, cx) {
    if (this.typing) {
      if (e.key !== "escape") return;
      this.keys.focus();
    } else if (e.modifiers.control || e.modifiers.alt || e.modifiers.platform || !this.walk(e.key, cx)) return;
    cx.stop_propagation();
    cx.notify();
  }

  // Up and down move between cards (inside an open detail they show the next card's detail); Enter opens a card, and
  // on your turn puts the keyboard in the answer field; Left and Esc close the detail. In a detail: a answers, f focuses
  // or p peeks at the worker (as its row offers), r revives it, o opens the PR. Answers whether it was a key of ours.
  walk(key, cx) {
    if (key === "escape" || key === "left") {
      if (!this.openId) return key === "left";
      this.closeDetail();
      return true;
    }
    const act = this.openId && this.shownDetail?.keys?.[key];
    if (act) { act(cx); return true; }
    const { ids, you } = this.nav;
    if (key === "up" || key === "down") {
      if (!ids.length) return true;
      const i = ids.indexOf(this.cursor);
      const next = ids[Math.max(0, Math.min(ids.length - 1, i + (key === "down" ? 1 : -1)))];
      this.cursor = next;
      if (this.nav.rows) this.treeScroll.scroll_to_item(ids.indexOf(next));
      if (this.openId) this.open(next, cx);
      return true;
    }
    if (key !== "enter") return false;
    if (this.cursor && ids.includes(this.cursor)) this.open(this.cursor, cx, you?.has(this.cursor));
    return true;
  }

  // ----- render ----------------------------------------------------------------------------------------------------

  render(cx) {
    const t = palette(), now = Date.now();
    const fixture = this.mode === "fixture";
    const agentList = agents(), terms = coreTerminals();
    const listed = new Map(agentList.map((a) => [a.address, a.status]));
    const namerFn = namer();
    // A listed agent goes through the rail's rule with its agents() entry (it carries the tab and title).
    const entry = new Map(agentList.map((a) => [a.address, a]));
    const nameOf = (k) => termName(entry.has(k.address) ? { ...k, ...entry.get(k.address) } : k, namerFn, listed);
    let roots = buildRoots({ agents: agentList, terminals: terms, spaces: spaces(), nameOf });
    if (fixture && !roots.length) roots = [SAMPLE_ROOT()];

    // fleet.open: a task asked for by another mod, once per `at`. Its orchestrator is drawn whatever is focused, until
    // the focus moves to some other agent.
    const fa = focused()?.agent ?? null;
    const req = shared("fleet.open");
    if (req?.at && req.at !== this.fleetOpenAt) {
      this.fleetOpenAt = req.at;
      if (req.orch && req.bead && now - req.at < OPEN_WAIT) {
        this.pendingOpen = req;
        this.pin = { orch: req.orch, focus: fa };
        // A read that starts now: what was loaded before the request may predate its epic.
        if (this.mode === "live") cx.timer.after(0, (cx) => this.loadSession(cx, req.orch));
      }
    }
    // The pin ends when the focus moves to an agent outside that orchestrator's tree; inside it, it just follows.
    if (this.pin && fa !== this.pin.focus) {
      const ours = fa === this.pin.orch || roots.some((r) => r.address === this.pin.orch && descendants(r.node).some((n) => n.address === fa));
      if (ours) this.pin.focus = fa; else this.pin = null;
    }
    // The focused agent: focused().agent, or the root above it when that's one of its sub-agents; else (a shell has the
    // focus) the one shown before.
    const sel = (this.pin && roots.find((r) => r.address === this.pin.orch))
      ?? roots.find((r) => r.address === fa)
      ?? roots.find((r) => descendants(r.node).some((n) => n.address === fa))
      ?? roots.find((r) => r.address === this.selAddr) ?? (fixture ? roots[0] : null);
    const selAddr = sel?.address ?? null;
    if (selAddr !== this.selAddr) {
      this.selAddr = selAddr;
      this.cursor = null;
      this.closeDetail();
    }
    const orch = Boolean(sel && (sel.orch || fixture));
    this.orchAddr = orch && !fixture ? selAddr : null;

    // Beads: the drawn orchestrator's own session only, read while the panel shows and the window is visible.
    const shown = this.isShown() && !checking() && Boolean(window()?.visible);
    // On show, and when another orchestrator is drawn while shown.
    if (shown && this.orchAddr && (!this.wasShown || this.askedFor !== this.orchAddr)) {
      const address = this.orchAddr;
      this.askedFor = address;
      cx.timer.after(0, (cx) => this.loadSession(cx, address));
    }
    this.wasShown = shown;
    const loaded = orch && !fixture ? this.data.get(selAddr) ?? null : null;
    const session = orch ? (fixture ? fixtureSession(this.fixtureAt) : loaded?.session ?? null) : null;
    const view = session ? sessionView({
      session,
      terms: fixture ? [...terms, ...fixtureTerms()] : terms,
      listed,
      hibernated: fixture ? fixtureHibernated(this.fixtureAt) : shared(HIBERNATED) ?? [],
      now,
    }) : null;
    const root = sel;

    // One clock: every node drawn is observed; a first sight asks the core, and redraws once the answers land.
    const msOf = new Map(terms.map((k) => [k.address, Number(k.status_ms) || 0]));
    const seen = new Set();
    const observe = (address, status) => {
      if (!address || seen.has(address)) return;
      seen.add(address);
      this.clock.observe(address, status, msOf.get(address) ?? 0, now);
    };
    if (root) for (const n of [root.node, ...descendants(root.node)]) if (n.live) observe(n.address, n.status);
    for (const task of view?.tasks ?? []) {
      if (task.worker?.address && task.worker.term) observe(task.worker.address, task.worker.status);
      for (const r of task.reviewers) if (r.worker?.address && r.worker.term) observe(r.worker.address, r.worker.status);
    }
    const asked = this.clock.takePending();
    if (asked.length) cx.spawn(async (cx) => { await Promise.allSettled(asked); cx.notify(); });
    // What isn't drawn any more is forgotten (its pulses' flips with it).
    this.clock.prune([...seen, ...terms.filter((k) => (k.state ?? "live") === "live").map((k) => k.address)]);

    // Pulses: a worker's status flip and a fresh orch.in label each draw a dot on the spine.
    for (const task of view?.tasks ?? []) {
      const worker = task.worker;
      if (!worker?.address) continue;
      for (const p of pulsesOf({ task, flip: this.clock.flip(worker.address), label: worker.term?.labels?.["orch.in"], now })) {
        if (this.pulses.has(p.key) || this.pulseSeen.has(p.key)) continue;
        this.pulseSeen.set(p.key, now);
        const pulse = { ...p, taskId: task.id, born: now, armed: false };
        this.pulses.set(p.key, pulse);
        // The dot draws at its start first; the beat arms it (its target set, GPUI slides it), then one timer ends it.
        cx.timer.after(PULSE_BEAT, (cx) => {
          pulse.armed = true;
          cx.notify();
          cx.timer.after(PULSE_LIFE - PULSE_BEAT, (cx) => { this.pulses.delete(p.key); cx.notify(); });
        });
      }
    }
    for (const [k, at] of this.pulseSeen) if (now - at > 60000) this.pulseSeen.delete(k);

    // What the keys walk: task cards in order, or the terminal tree's.
    const ids = view ? view.tasks.map((x) => x.id) : root ? descendants(root.node).map((n) => n.id) : [];
    const solo = Boolean(root && isSolo(root, Boolean(view)));
    this.nav = { ids, rows: Boolean(view), you: new Set(view?.tasks.filter((x) => x.turn === "you").map((x) => x.id) ?? []) };
    if (this.cursor && !ids.includes(this.cursor)) this.cursor = null;

    // The pending fleet.open lands once its orchestrator's session (that epic) has the task; state only, no notify.
    if (this.pendingOpen) {
      const r = this.pendingOpen;
      const epicOk = !r.epic || view?.epic?.id === r.epic;
      if (selAddr === r.orch && view && epicOk && ids.includes(r.bead)) {
        this.pendingOpen = null;
        this.showDetail(r.bead, cx);
      } else if (now - r.at > OPEN_WAIT || (selAddr === r.orch && (loaded?.startedAt ?? 0) >= r.at && (!view || !epicOk || !ids.includes(r.bead)))) {
        // Dropped only when a read started after the request lacks the task, or it waited too long.
        this.pendingOpen = null;
      }
    }
    if (this.openId && !solo && !ids.includes(this.openId)) this.closeDetail();
    const openTask = view && this.openId ? view.tasks.find((x) => x.id === this.openId) ?? null : null;
    const openNode = !view && root && this.openId ? descendants(root.node).find((n) => n.id === this.openId) ?? null : null;

    const side = this.width >= SIDE_AT;
    const slotsUsed = view?.mode?.max ? slotsOf(fixture ? fixtureTerms() : terms, fixture ? "tfx0" : selAddr) : 0;
    const reach = (address) => reachOf(address, panes(), focused()?.tab ?? null);
    const ui = { t, now, side, root, view, orch, fixture, loaded, slotsUsed, nameOf, reach };
    this.shownDetail = null;
    const frame = v_flex().id("fleet").track_focus(this.keys).on_key_down((e, cx) => this.onKey(e, cx))
      .on_size_change((sz, cx) => { if (Math.abs(sz.width - this.width) > 1) { this.width = sz.width; cx.notify(); } })
      .size_full().min_w(0).bg(t.canvas).text_color(t.foreground).text_size(BODY);
    if (!roots.length) return frame.child(this.empty(t)).child(this.footer(ui));
    if (!root) {
      return frame.child(div().p(16).text_size(BODY).line_height("20px").text_color(t.muted)
        .child("Pick an agent in the sidebar, or focus its pane, to see its workers and tasks here.")).child(this.footer(ui));
    }
    if (solo) return frame.child(this.terminalDetail(ui, root.node, { solo: true }).flex_1().min_h(0)).child(this.footer(ui));

    const colW = side ? TREE : this.width;
    const list = view ? this.taskList(ui, colW) : this.nodeList(ui, colW);
    const detail = openTask ? this.taskDetail(ui, openTask) : openNode ? this.terminalDetail(ui, openNode, {}) : null;
    if (!side && detail) return frame.child(detail.flex_1().min_h(0)).child(this.footer(ui));
    const head = this.header(ui);
    if (!side) return frame.child(head).child(list.flex_1().min_h(0)).child(this.footer(ui));
    return frame.child(head).child(h_flex().flex_1().min_h(0)
      .child(list.w(TREE).flex_none().h_full().border_r_1().border_color(t.border))
      .child((detail ?? this.placeholder(ui)).flex_1().h_full().min_w(0).min_h(0))).child(this.footer(ui));
  }

  // ----- chrome ----------------------------------------------------------------------------------------------------

  empty(t) {
    return v_flex().id("fleet-empty").max_w(460).mt(48).mx_auto().gap(10).items_center().text_center().px(16)
      .child(div().text_size(NAME).font_semibold().child("No agents are reporting yet"))
      .child(div().text_size(BODY).line_height("20px").text_color(t.muted)
        .child("Agents show up here once they report a status. Start one from the + menu in the tab bar, or from any terminal:"))
      .child(div().px(10).py(5).rounded(6).bg(t.background).border_1().border_color(t.border)
        .font_family(mono()).text_size(META).child("hc run -- claude"));
  }

  placeholder({ t }) {
    return v_flex().items_center().justify_center().p(24).text_size(BODY).text_color(t.muted)
      .child("Pick a card to see its detail here.");
  }

  footer({ t, fixture }) {
    const keys = this.typing ? "Enter sends · Esc leaves the field"
      : this.openId ? `↑↓ cards · Esc or ← closes${this.shownDetail?.hint ? ` · ${this.shownDetail.hint}` : ""}`
        : "↑↓ cards · Enter opens · Esc or ← closes";
    return h_flex().id("fleet-footer").h(30).flex_none().px(16).gap(16).items_center().border_t_1().border_color(t.border)
      .bg(t.chrome).text_size(META).text_color(t.muted)
      .child(div().min_w(0).truncate().child(keys))
      .child(div().flex_1())
      .when(fixture, (el) => el.child(div().flex_none().child("Sample data")));
  }

  // The drawn agent: its tile, name, state and how long it has held it; under it, for an orchestrator, its session.
  header(ui) {
    const { t, now, root, view, orch, fixture, loaded } = ui;
    const n = root.node;
    const state = n.live ? n.shown : n.status;
    // The rail card's own count when it has one (shared "panda-focus.since"), so both say the same; else the clock.
    const since = (shared("panda-focus.since") ?? {})[n.address] || this.clock.since(n.address);
    const held = n.live && since > 0 ? took(since, now) : "";
    const slots = view?.mode?.max ? `Slots ${ui.slotsUsed}/${view.mode.max}` : null;
    const program = n.app ?? n.program?.name ?? null;
    const plain = [program, root.space].filter(Boolean);
    const chip = (text, id) => div().id(id).flex_none().h(20).px(6).flex().items_center().rounded(5).bg(t.raised)
      .font_family(mono()).text_size(META).text_color(t.foreground).child(text);
    const meta = h_flex().gap(8).flex_wrap().items_center().text_size(META).text_color(t.muted)
      .child(div().min_w(0).truncate().child(plain.join(" · ") || n.address))
      .when(Boolean(view?.mode?.flags), (el) => el.child(chip(view?.mode?.flags ?? "", "mode-chip")))
      .when(Boolean(slots), (el) => el.child(chip(slots ?? "", "slots-chip")))
      .when(Boolean(view?.source), (el) => el.child(div().id("source").flex_none().tooltip(view?.source ?? "").child(`from ${sourceLabel(view?.source)}`)))
      .when(fixture, (el) => el.child(div().id("sample-chip").flex_none().h(20).px(6).flex().items_center().rounded(5)
        .border_1().border_color(t.input).tooltip("These tasks are a made-up sample (fleet.live for real ones)").child("Sample")));
    const top = h_flex().pt(14).pb(8).gap(10).items_start()
      .child(tile(t, n.program, 28))
      .child(v_flex().flex_1().min_w(0).gap(3)
        .child(div().min_w(0).truncate().text_size(NAME).font_semibold().child(n.name))
        .child(meta))
      .child(badge(t, state, agentWord(state), held));
    const sum = view?.summary;
    const bar = view && view.tasks.length ? h_flex().gap(3).pb(8).children(view.tasks.map((task) => div()
      .h(6).flex_1().rounded(3).bg(task.turn === "waiting" || task.turn === "slot" || task.turn === "queued" ? t.input : turnColor(t, task)))) : null;
    const under = root.node.children;
    const subline = view ? (sum?.text || "No tasks yet")
      : orch ? (loaded ? (loaded.error ? "" : "No open epic for this session") : "Reading beads…")
        : `${under.length} under it${under.filter((c) => c.status === "working" || c.status === "running").length ? ` · ${under.filter((c) => c.status === "working" || c.status === "running").length} working` : ""}`;
    const row = h_flex().pb(12).gap(8).items_center().text_size(META).text_color(t.muted)
      .child(div().flex_1().min_w(0).truncate().text_color(sum?.you ? t.foreground : t.muted).child(subline))
      .when(Boolean(view), (el) => el.child(button(t, "board", "Board", { h: 24, onClick: () => run("tab.new", { mod: "beads", name: "Beads", props: { epic: view?.epic.id } }) })))
      .when(Boolean(view) && Boolean(loaded?.extra), (el) => el.child(div().flex_none().child(`+${loaded?.extra} more epic${loaded?.extra === 1 ? "" : "s"}`)));
    return v_flex().id("fleet-header").flex_none().px(16).border_b_1().border_color(t.border).bg(t.chrome)
      .child(top).when(Boolean(bar), (el) => el.child(bar)).child(row);
  }

  // ----- the task list ---------------------------------------------------------------------------------------------

  warning(ui) {
    const { t, loaded, orch, view, fixture } = ui;
    if (!orch || fixture) return null;
    if (loaded?.error) {
      return h_flex().id("beads-warning").gap(6).items_start().px(16).pt(10).text_size(META).text_color(t.blocked)
        .child(svg(`${ME}/alert.svg`).size(12).flex_none().mt(2).text_color(t.blocked)).child(div().min_w(0).child(`Beads: ${loaded.error}`));
    }
    if (!loaded && !view) return div().px(16).pt(10).text_size(META).text_color(t.muted).child("Reading beads…");
    return null;
  }

  taskList(ui, colW) {
    const { t, view } = ui;
    const rows = view.tasks.map((task, i) => this.taskRow(ui, task, i, view.tasks.length, colW));
    return v_flex().min_w(0).min_h(0)
      .child(this.warning(ui) ?? div())
      .child(rows.length === 0
        ? div().px(16).pt(14).text_size(BODY).text_color(t.muted).child("This session has no tasks yet.")
        : v_flex().id("fleet-tasks").flex_1().min_h(0).overflow_y_scrollbar().track_scroll(this.treeScroll).px(16).pt(16).pb(24).children(rows));
  }

  taskRow(ui, task, i, count, colW) {
    const { t, now } = ui;
    const c = turnColor(t, task);
    const pulse = [...this.pulses.values()].filter((p) => p.taskId === task.id).sort((a, b) => b.born - a.born)[0] ?? null;
    const quiet = task.turn === "waiting" || task.turn === "slot" || task.turn === "queued";
    const fill = task.turn === "done" || task.turn === "you";
    const first = i === 0, last = i === count - 1;
    const spine = div().absolute().left(10).w(2).rounded(1).bg(t.border)
      .top(first ? NODE_Y : 0).when(last, (el) => el.h(NODE_Y)).when(!last, (el) => el.bottom(0));
    const node = div().absolute().left(5).top(NODE_Y - 6).size(12).rounded_full().border_2().border_color(quiet ? t.muted : c)
      .bg(fill ? c : t.canvas);
    // Drawn at its start on the render that sees it; ~50 ms later its target is set and GPUI slides it, then fades it.
    const start = pulse && !pulse.armed;
    const dot = pulse && div().id(`pulse-${pulse.key}`).absolute().left(7).size(8).rounded_full().bg(t[pulse.tone])
      .top(start ? (pulse.down ? -14 : NODE_Y - 4) : (pulse.down ? NODE_Y - 4 : -14))
      .opacity(start ? 1 : 0)
      .transition("top", { duration: 650, easing: "ease-out" })
      .transition("opacity", { duration: 300, delay: 650 });
    const cardW = colW - 32 - GUTTER - 26;
    const card = task.turn === "done" ? this.foldedCard(ui, task, pulse, start)
      : quiet && task.life.stop === 0 ? this.waitingCard(ui, task, pulse, start)
        : this.activeCard(ui, task, pulse, start, cardW);
    return v_flex().relative().pl(GUTTER).pb(10).when(count > 1, (el) => el.child(spine)).child(node).when(Boolean(dot), (el) => el.child(dot)).child(card);
  }

  // The card's shell: its border, fill, the keyboard's ring and a pulse's flash.
  shell(ui, task, { dashed = false, pulse, start }) {
    const { t } = ui;
    const open = this.openId === task.id, cursor = this.cursor === task.id, ring = cursor && this.keys.is_focused();
    return v_flex().id(`task-${task.id}`).relative().w_full().min_w(0).rounded(12).border_1()
      .bg(open || ring ? t.selected : t.background).border_color(open ? t.accent : t.border)
      .cursor_pointer().hover((s) => s.border_color(open ? t.accent : t.input))
      .role("button").accessibility_label(`${task.key}, ${turnWord(task)}, ${task.title}`)
      .on_click((_e, cx) => { this.keys.focus(); this.open(task.id, cx); })
      .when(dashed, (el) => el.border_dashed())
      .when(Boolean(pulse), (el) => el.child(div().id(`flash-${task.id}`).absolute().inset_0().rounded(12).border_1()
        .border_color(t[pulse.tone]).bg(tint(t[pulse.tone], "1f"))
        .opacity(start ? 1 : 0).transition("opacity", { duration: 1200, easing: "ease-out" })))
      .when(ring, (el) => el.child(div().absolute().inset_0().rounded(12).border_2().border_color(t.accent)));
  }

  // Settled: one line, its result in the result's color.
  foldedCard(ui, task, pulse, start) {
    const { t, now } = ui;
    const c = turnColor(t, task);
    const pr = prNumber(task.life.pr);
    const when = task.since ? ago(task.since, now) : "";
    return this.shell(ui, task, { pulse, start }).px(10).min_h(32).py(4).flex_row().items_center().gap(8)
      .child(keyChip(t, task.key))
      .child(div().flex_1().min_w(0).truncate().text_size(META).text_color(t.muted).child(task.title))
      .child(div().flex_none().text_size(META).font_medium().text_color(c)
        .child([turnWord(task), pr ? `#${pr}` : "", when && when !== "just now" ? when : ""].filter(Boolean).join(" · ")))
      .child(task.life.result && task.life.result !== "succeeded" && task.life.result !== "closed" ? glyph("failed", c)
        : svg("mods/workspace-chrome/circle-check.svg").size(14).flex_none().text_color(c));
  }

  // Queued, waiting on a task or on a slot: dashed, with what it waits on.
  waitingCard(ui, task, pulse, start) {
    const { t } = ui;
    return this.shell(ui, task, { dashed: true, pulse, start }).px(12).py(9).gap(5)
      .child(h_flex().gap(8).items_center().text_size(META).text_color(t.muted)
        .child(keyChip(t, task.key))
        .child(h_flex().gap(4).items_center().min_w(0)
          .child(task.turn === "waiting" ? svg(`${ME}/lock.svg`).size(12).flex_none().text_color(t.muted) : glyph("queued", t.muted))
          .child(div().truncate().child(turnWord(task)))))
      .child(div().text_size(BODY).line_height("18px").text_color(t.foreground).child(task.title));
  }

  workerLine(ui, task, w, id) {
    const { t, now } = ui;
    if (!w) {
      return task.life.stop >= 1 ? div().text_size(META).text_color(t.muted).child("No worker terminal") : null;
    }
    const since = w.address ? this.clock.since(w.address) : 0;
    const asleep = w.status === "hibernated";
    const age = asleep ? ago(w.hibernated?.at, now) : since > 0 ? took(since, now) : "";
    return h_flex().gap(8).items_center().min_h(24).min_w(0)
      .child(tile(t, w.term?.program ?? w.hibernated?.program ?? null, 18))
      .child(div().flex_1().min_w(0).truncate().text_size(META).text_color(t.foreground).child(ui.nameOf(w.term ?? w)))
      .child(h_flex().gap(5).items_center().flex_none().text_size(META).text_color(asleep ? t.muted : agentColor(t, w.status))
        .child(glyph(w.status, agentColor(t, w.status), 12)).child(agentWord(w.status))
        .when(Boolean(age), (el) => el.child(div().text_color(t.muted).child(age))))
      .when(asleep && Boolean(w.hibernated), (el) => el.child(button(t, `revive-${id}`, this.reviving.has(w.hibernated.address) ? "Reviving…" : "Revive",
        { h: 24, enabled: !this.reviving.has(w.hibernated.address), onClick: (cx) => this.reviveRow(w.hibernated, cx) })));
  }

  activeCard(ui, task, pulse, start, cardW) {
    const { t, now } = ui;
    const prs = shared("panda-spaces.prs");
    const pr = task.life.pr ? prFor(prs, task.life.pr) : null;
    const prN = prNumber(task.life.pr);
    const pulseLine = pulse ? `${pulse.down ? "↓" : "↑"} ${pulse.kind || (pulse.down ? "sent" : "answered")}` : "";
    const dim = [pulseLine, newestLine(task, now)].filter(Boolean).join(" · ");
    const ask = task.turn === "you" ? task.life.holdQuestion : null;
    return this.shell(ui, task, { pulse, start }).px(12).py(10).gap(7)
      .child(h_flex().gap(8).items_center().min_w(0)
        .child(keyChip(t, task.key))
        .when(Boolean(prN), (el) => el.child(prChip(t, prN, pr)))
        .child(div().flex_1())
        .child(turnChip(t, task, `chip-${task.id}`)))
      .child(div().text_size(BODY).font_medium().line_height("18px").child(task.title))
      .when(Boolean(ask), (el) => el.child(div().text_size(BODY).line_height("18px").text_color(t.foreground).child(`Asks: ${ask}`)))
      .when(task.life.stop >= 1, (el) => el.child(strip(t, task, cardW)))
      .child(this.workerLine(ui, task, task.worker, `w-${task.id}`) ?? div())
      .children(task.reviewers.map((r) => h_flex().gap(8).items_center().min_h(24).min_w(0).text_size(META).text_color(t.muted)
        .child(tile(t, r.worker?.term?.program ?? null, 18))
        .child(div().flex_1().min_w(0).truncate().child(reviewLabel(task, r)))
        .when(r.open && Boolean(r.worker) && r.worker.status !== "ended", (el) => el.child(div().flex_none().text_color(agentColor(t, r.worker.status))
          .child(agentWord(r.worker.status))))))
      .child(div().text_size(META).text_color(t.muted).truncate().child(dim));
  }

  // ----- the terminal tree (agents without a session) --------------------------------------------------------------

  nodeList(ui, colW) {
    const { t, root } = ui;
    const kids = root.node.children;
    const depth = (n) => (n.children.length ? 1 + Math.max(...n.children.map(depth)) : 0);
    const d = Math.max(1, depth(root.node));
    const child = Math.max(200, Math.min(440, colW - 40 - ARM - (d - 1) * (16 + ARM)));
    return v_flex().min_w(0).min_h(0)
      .child(this.warning(ui) ?? div())
      .child(v_flex().id("fleet-tree").flex_1().min_h(0).overflow_y_scrollbar().track_scroll(this.treeScroll).px(16).pt(14).pb(24)
        .child(this.branch(ui, kids, "top", child)));
  }

  // Children down a spine: each row an arm into its card, the spine running on past all but the last, which turns into
  // its card on a rounded elbow. A child's own children hang under it the same way.
  branch(ui, nodes, entry, cardW) {
    const line = ui.t.accent;
    return v_flex().children(nodes.map((n, i) => {
      const first = i === 0, last = i === nodes.length - 1;
      const pad = first && entry === "side" ? 0 : GAP;
      const y = pad + ANCHOR;
      const above = !first || entry === "top";
      const arm = div().relative().w(ARM).flex_none().self_stretch()
        .when(above && last, (el) => el.child(div().absolute().top(0).left(0).w(ARM).h(y + 1).border_l_1().border_b_1().rounded_bl(7).border_color(line)))
        .when(above && !last, (el) => el.child(div().absolute().top(0).left(0).w(1).h(y).bg(line)))
        .when(!(above && last), (el) => el.child(div().absolute().top(y).left(0).w(ARM).h(1).bg(line)))
        .when(!last, (el) => el.child(div().absolute().top(y).left(0).bottom(0).w(1).bg(line)));
      return h_flex().items_start().child(arm)
        .child(v_flex().pt(pad).items_start()
          .child(this.nodeCard(ui, n, cardW))
          .when(n.children.length > 0, (el) => el.child(div().pl(16).child(this.branch(ui, n.children, "top", cardW)))));
    }));
  }

  nodeCard(ui, n, cardW) {
    const { t, now } = ui;
    const open = this.openId === n.id, cursor = this.cursor === n.id, ring = cursor && this.keys.is_focused();
    const since = n.live ? this.clock.since(n.address) : 0;
    const age = since > 0 ? took(since, now) : "";
    const meta = [n.app, n.address].filter((x, i, all) => x && all.indexOf(x) === i).join(" · ");
    return v_flex().id(`card-${n.id}`).relative().w(cardW).flex_none().px(12).py(10).gap(6).rounded(12).border_1()
      .bg(open || ring ? t.selected : t.background).border_color(open ? t.accent : t.border)
      .cursor_pointer().hover((s) => s.border_color(open ? t.accent : t.input))
      .role("button").accessibility_label(`${n.name}, ${agentWord(n.shown)}`)
      .on_click((_e, cx) => { this.keys.focus(); this.open(n.id, cx); })
      .when(ring, (el) => el.child(div().absolute().inset_0().rounded(12).border_2().border_color(t.accent)))
      .child(h_flex().gap(9).items_start()
        .child(tile(t, n.program, 24))
        .child(v_flex().flex_1().min_w(0).gap(1)
          .child(h_flex().gap(8).items_center()
            .child(div().flex_1().min_w(0).text_size(BODY).font_medium().truncate().child(n.name))
            .child(badge(t, n.shown, agentWord(n.shown))))
          .child(h_flex().gap(8).text_size(META).text_color(t.muted)
            .child(div().flex_1().min_w(0).truncate().child(meta))
            .when(Boolean(age), (m) => m.child(div().flex_none().child(age))))))
      .when(Boolean(n.report), (el) => el.child(div().text_size(META).text_color(t.muted).truncate().child(firstLine(n.report))))
      .when(n.children.length > 0, (el) => el.child(div().text_size(META).text_color(t.muted).child(`${n.children.length} under it`)));
  }

  // ----- details ---------------------------------------------------------------------------------------------------

  // The bar over a detail: narrow, a breadcrumb back to the orchestrator; beside the tree, a close button.
  bar(ui, label) {
    const { t, side, root } = ui;
    const back = (cx) => { this.closeDetail(); cx.notify(); };
    return h_flex().h(40).flex_none().px(10).gap(8).items_center().border_b_1().border_color(t.border).bg(t.chrome)
      .child(side
        ? div().min_w(0).truncate().text_size(META).text_color(t.muted).child(label)
        : h_flex().id("crumb").h(28).px(8).gap(6).items_center().rounded(6).min_w(0).cursor_pointer().role("button")
          .accessibility_label(`Back to ${root.node.name}`).text_size(BODY).text_color(t.muted)
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => back(cx))
          .child(svg("mods/workspace-chrome/chevron-left.svg").size(14).flex_none())
          .child(div().min_w(0).truncate().child(root.node.name)))
      .child(div().flex_1())
      .when(side, (el) => el.child(div().id("detail-close").size(28).flex_none().flex().items_center().justify_center().rounded(6)
        .cursor_pointer().role("button").accessibility_label("Close detail").text_color(t.muted)
        .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => back(cx))
        .child(svg("mods/workspace-chrome/x.svg").size(14))));
  }

  // The answer field, as one row. What Send reaches is decided when it is pressed (submit), from what shows then.
  answerRow(t, id) {
    return h_flex().gap(8).items_center()
      .child(Input.new(this.answer).flex_1().h(30).px(10).rounded(6).border_1()
        .border_color(this.typing ? t.accent : t.input).bg(t.background).text_size(BODY).text_color(t.foreground))
      .child(button(t, id, this.sending ? "Sending…" : "Send", { primary: true, enabled: !this.sending, onClick: (cx) => this.submit(cx) }));
  }

  noteLine(t) {
    return this.note ? div().text_size(META).line_height("16px").text_color(this.note.error ? t.blocked : t.muted).child(this.note.text) : null;
  }

  // Your turn: the question, whole, above the answer field. The answer goes to the orchestrator, which records it.
  // The field answers the question it was opened on: a newer question on the same task is flagged at Send.
  yourTurn(ui, task, route) {
    const { t, root } = ui;
    const question = task.life.holdQuestion || "";
    const qid = task.life.holdQuestionId;
    // The question on screen, for the field's change handler; an empty field belongs to it already.
    this.askedNow = route === "answer" && qid ? { taskId: task.id, qid } : null;
    if (!this.answer.value().trim()) this.asking = this.askedNow;
    const stale = route === "answer" && Boolean(this.asking) && Boolean(this.answer.value().trim())
      && (this.asking.taskId !== task.id || this.asking.qid !== qid);
    const note = this.noteLine(t);
    const block = v_flex().gap(8).p(12).rounded(10).border_1().border_color(tint(t.blocked, "66")).bg(tint(t.blocked, "14"))
      .child(h_flex().gap(6).items_center().text_size(BODY).font_semibold().text_color(t.blocked)
        .child(svg(`${ME}/user.svg`).size(13).flex_none().text_color(t.blocked)).child("Your turn"))
      .child(div().text_size(BODY).line_height("19px").text_color(t.foreground).child(question || "The orchestrator asked for your answer."))
      .when(stale, (el) => el.child(div().text_size(META).line_height("16px").text_color(t.blocked)
        .child("This question replaced the one your draft answers. Edit the draft to answer this one.")))
      .when(route === "answer" && Boolean(qid), (el) => el.child(this.answerRow(t, "act-send"))
        .child(div().text_size(META).line_height("16px").text_color(t.muted)
          .child("Goes to the orchestrator with this bead and question, which records your decision and clears the hold.")))
      .when(route === "answer" && !qid, (el) => el.child(div().text_size(META).line_height("16px").text_color(t.muted)
        .child("No question is recorded on the bead, so there is nothing to answer here. Ask in the orchestrator's pane.")))
      .when(route === "orch-blocked", (el) => el.child(div().text_size(BODY).font_medium().child("Answer in the orchestrator's pane"))
        .child(h_flex().gap(8).items_center().flex_wrap()
          .child(button(t, "act-orch-focus", "Focus the orchestrator", { primary: true, onClick: () => this.focusTerm(root.address) }))
          .child(div().text_size(META).text_color(t.muted).child("It is stopped on its own dialog, so it can't take the answer."))))
      .when(route === "no-orch", (el) => el.child(div().text_size(BODY).font_medium().child("The orchestrator isn't running"))
        .child(div().text_size(META).line_height("16px").text_color(t.muted).child("Nothing can record an answer. Start it again, or answer in its pane.")));
    return v_flex().gap(6).child(block).when(Boolean(note), (el) => el.child(note));
  }

  // Focus or Peek, as the session's place allows (model.js reachOf): none for an agent already on screen.
  reachButtons(ui, address, id, { tool = false, primary = false } = {}) {
    const { t } = ui;
    const how = ui.reach(address);
    if (how === "focus") return [button(t, `focus-${id}`, "Focus", { h: 24, primary, onClick: () => this.focusTerm(address, tool) })];
    if (how === "peek") return [button(t, `peek-${id}`, "Peek", { h: 24, primary, onClick: () => this.peek(address) })];
    return [];
  }

  workerPrompt(ui, task) {
    const { t } = ui;
    const w = task.worker;
    const buttons = w.term ? this.reachButtons(ui, w.address, "prompt") : [];
    return v_flex().gap(8).p(12).rounded(10).border_1().border_color(t.border).bg(t.background)
      .child(div().text_size(BODY).font_semibold().child("Waiting on the orchestrator"))
      .child(div().text_size(META).line_height("16px").text_color(t.muted).child(`${ui.nameOf(w.term ?? w)} is at a prompt. The orchestrator answers worker prompts.`))
      .when(buttons.length > 0, (el) => el.child(h_flex().gap(8).children(buttons)));
  }

  // A worker or reviewer: who, its state, and what can be done with it.
  sessionRow(ui, label, w, id) {
    const { t, now } = ui;
    if (!w) return null;
    const asleep = w.status === "hibernated";
    const live = Boolean(w.term) && (w.term.state ?? "live") === "live";
    const since = w.address ? this.clock.since(w.address) : 0;
    const buttons = live ? this.reachButtons(ui, w.address, id) : [];
    const reviving = Boolean(w.hibernated) && this.reviving.has(w.hibernated.address);
    return v_flex().gap(4)
      .child(h_flex().gap(8).items_center().min_w(0)
        .child(tile(t, w.term?.program ?? w.hibernated?.program ?? null, 20))
        .child(v_flex().flex_1().min_w(0)
          .child(div().truncate().text_size(BODY).text_color(t.foreground).child(ui.nameOf(w.term ?? w)))
          .child(div().truncate().text_size(META).text_color(t.muted).child(label)))
        .child(h_flex().gap(5).items_center().flex_none().text_size(META).text_color(agentColor(t, w.status))
          .child(glyph(w.status, agentColor(t, w.status))).child(agentWord(w.status))
          .when(since > 0 && live, (el) => el.child(div().text_color(t.muted).child(took(since, now))))))
      .when(buttons.length > 0 || (asleep && Boolean(w.hibernated)) || (!live && !asleep), (el) => el.child(h_flex().gap(8).pl(28)
        .children(buttons)
        .when(asleep && Boolean(w.hibernated), (r) => r.child(button(t, `revive-d-${id}`, reviving ? "Reviving…" : "Revive",
          { h: 24, enabled: !reviving, onClick: (cx) => this.reviveRow(w.hibernated, cx) })))
        .when(!live && !asleep, (r) => r.child(div().text_size(META).text_color(t.muted).child("Its terminal has ended.")))));
  }

  link(t, id, icon, label, onClick, extra = null) {
    return h_flex().id(id).h(24).px(8).gap(6).items_center().rounded(6).border_1().border_color(t.input).bg(t.raised)
      .text_size(META).font_medium().text_color(t.foreground).cursor_pointer().role("button").accessibility_label(label)
      .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
      .child(svg(icon).size(12).flex_none().text_color(t.muted)).child(label)
      .when(Boolean(extra), (el) => el.child(extra));
  }

  // A task: your turn first, then its strip, links, sessions and timeline.
  taskDetail(ui, task) {
    const { t, now, side, root } = ui;
    const route = answerState(task, { live: root.node.live, status: root.node.status });
    const innerW = (side ? this.width - TREE - 1 : this.width) - 32;
    const prs = shared("panda-spaces.prs");
    const pr = task.life.pr ? prFor(prs, task.life.pr) : null;
    const prN = prNumber(task.life.pr);
    // The task's events with its reviewers' reports, each round's report under the round it answers.
    const reports = task.reviewers.flatMap((r) => (r.events ?? []).filter((e) => e.name === "report"));
    const events = reports.length ? [...task.events, ...reports].sort((a, b) => (a.at ?? 0) - (b.at ?? 0)) : task.events;
    const data = timelineOf(events, now);
    // The timeline stays at its end: on open, and when it grows while it was at the end.
    const sc = this.tlScroll;
    const atEnd = sc.offset().y + sc.viewport_size().height >= sc.content_size().height - 1;
    if (data.count !== this.tlCount) { if (this.tlCount === 0 || atEnd) this.tlJump = true; this.tlCount = data.count; }
    const programs = { worker: task.worker?.term?.program ?? null, reviewer: task.reviewers[0]?.worker?.term?.program ?? null };
    const on = {
      filter: (k, cx) => { this.tl.filter = k; this.tlJump = true; cx.notify(); },
      round: (key, open, cx) => { this.tl.rounds.set(key, open); cx.notify(); },
      event: (key, cx) => { if (this.tl.ev.has(key)) this.tl.ev.delete(key); else this.tl.ev.add(key); cx.notify(); },
    };
    const timeline = timelineView(t, data, this.tl, programs, on);
    // A reviewer reused across rounds is one session: its row names every round it held.
    const byWorker = new Map();
    for (const r of task.reviewers) {
      const key = r.worker?.address ?? `round-${r.round}`;
      byWorker.set(key, { ...(byWorker.get(key) ?? {}), worker: r.worker, rounds: [...(byWorker.get(key)?.rounds ?? []), r] });
    }
    const sessions = [this.sessionRow(ui, "Worker", task.worker, `w-${task.id}`),
      ...[...byWorker.values()].map(({ worker, rounds }) => this.sessionRow(ui,
        // Ids name the reviewer too: parallel reviewers of one round each get their own buttons.
        rounds.map((r) => reviewLabel(task, r)).join(" · "), worker,
        `r${rounds.at(-1).round}-${worker?.name ?? rounds.at(-1).bead.assignee ?? rounds.at(-1).bead.id}-${task.id}`))].filter(Boolean);
    const deps = [task.waitsOn.length ? `Waits on ${task.waitsOn.map((d) => d.key).join(", ")}` : "",
      task.blocks.length ? `Unblocks ${task.blocks.map((d) => d.key).join(", ")}` : ""].filter(Boolean);
    // The detail's keys (walk): what its buttons do, when they show.
    const w = task.worker;
    const keys = {};
    const hint = [];
    if (route === "answer" && task.life.holdQuestionId) { keys.a = () => this.answer.focus(); hint.push("a answers"); }
    const wReach = w?.term && (w.term.state ?? "live") === "live" ? ui.reach(w.address) : null;
    if (wReach === "focus") { keys.f = () => this.focusTerm(w.address); hint.push("f focuses the worker"); }
    if (wReach === "peek") { keys.p = () => this.peek(w.address); hint.push("p peeks at the worker"); }
    if (w?.status === "hibernated" && w.hibernated) { keys.r = (cx) => this.reviveRow(w.hibernated, cx); hint.push("r revives"); }
    if (prN) { keys.o = (cx) => this.openPr(pr, task.life.pr, cx); hint.push("o opens the PR"); }
    this.shownDetail = { kind: "task", task, route, orch: root.address, keys, hint: hint.join(" · ") };
    // Everything above the timeline's rows stays put; the rows are the detail's one scroll area and fill the rest.
    const fixed = v_flex().id("detail-fixed").flex_none().min_w(0).gap(14)
      .on_size_change((sz, cx) => { if (Math.abs(sz.height - this.fixedH) > 1) { this.fixedH = sz.height; cx.notify(); } })
      .child(v_flex().gap(8)
        .child(h_flex().gap(8).items_center().flex_wrap().child(keyChip(t, task.key)).child(turnChip(t, task, "chip-detail"))
          .when(Boolean(task.life.hold) && task.turn !== "you", (el) => el.child(div().text_size(META).text_color(t.blocked)
            .child(`Held: ${reasonWord(task.life.hold === "blocked" ? "" : task.life.hold) || "Blocked"}`))))
        .child(div().text_size(NAME).font_semibold().line_height("21px").child(task.title)))
      .when(route === "answer" || route === "orch-blocked" || route === "no-orch", (el) => el.child(this.yourTurn(ui, task, route)))
      .when(route === "worker-prompt", (el) => el.child(this.workerPrompt(ui, task)))
      .when(task.life.stop >= 1, (el) => el.child(strip(t, task, innerW)))
      .when(Boolean(task.url) || Boolean(prN) || deps.length > 0, (el) => el.child(v_flex().gap(6)
        .child(h_flex().gap(8).flex_wrap()
          .when(Boolean(task.url), (r) => r.child(this.link(t, "link-ticket", `${ME}/external.svg`, task.key, (cx) => cx.open_url(task.url))))
          .when(Boolean(prN), (r) => r.child(this.link(t, "link-pr", `${ME}/merge.svg`, `PR #${prN}`, (cx) => this.openPr(pr, task.life.pr, cx),
            ciMark(t, pr))))
        )
        .when(deps.length > 0, (r) => r.child(div().text_size(META).text_color(t.muted).child(deps.join(" · ")))))
      )
      .when(sessions.length > 0, (el) => el.child(v_flex().gap(10).child(section(t, "Sessions", null)).children(sessions)))
      .child(timeline.head);
    // A panel too short to leave the events TIMELINE_MIN: the whole detail scrolls as one area, so nothing clips. The
    // events' room is the detail less its bar, the fixed part, the body's top padding, the gap and the bottom padding.
    const zoom = Number(settings()?.zoom) || 1;
    const measured = this.detailH > 0 && this.fixedH > 0;
    const room = this.detailH - (DETAIL_BAR + DETAIL_PAD) * zoom - this.fixedH;
    const short = measured && room < TIMELINE_MIN * zoom;
    // Switching layouts moves the scroll to another element: when the events were at their end, jump there again.
    if (this.tlShort !== short) {
      if (this.tlAtEnd !== false) this.tlJump = true;
      this.tlShort = short;
    }
    this.tlAtEnd = atEnd;
    const rows = v_flex().id(`tl-${task.id}`).min_w(0).pr(4).children(timeline.rows);
    // Short: the events are direct children of the one scroll area, with no gap between them (the spine stays whole).
    const body = short
      ? v_flex().id("detail-body").flex_1().min_h(0).min_w(0).overflow_y_scrollbar().track_scroll(sc).px(16).pt(14).pb(20)
        .child(fixed).child(div().h(14).flex_none()).children(timeline.rows)
      : v_flex().id("detail-body").flex_1().min_h(0).min_w(0).px(16).pt(14).gap(14)
        .child(fixed).child(rows.flex_1().min_h(0).pb(20).overflow_y_scrollbar().track_scroll(sc));
    // The newest event, once the layout is measured (a jump spent on the wrong element would be lost): a direct child of
    // whichever area scrolls (after the fixed part and its spacer when the detail scrolls whole).
    if (this.tlJump && this.tl.last >= 0 && measured) { this.tlJump = false; sc.scroll_to_item(this.tl.last + (short ? 2 : 0)); }
    return v_flex().id("fleet-detail").min_h(0).bg(t.popover)
      .on_size_change((sz, cx) => { if (Math.abs(sz.height - this.detailH) > 1) { this.detailH = sz.height; cx.notify(); } })
      .child(this.bar(ui, `${task.key} · ${root.node.name}`))
      .child(body);
  }

  // A terminal of the tree, or the solo agent: its report, Focus or Peek as its place allows, and an answer field when
  // it is blocked. An orchestrator's workers are the orchestrator's to answer, so they get none.
  terminalDetail(ui, n, { solo = false }) {
    const { t, now } = ui;
    const since = n.live ? this.clock.since(n.address) : 0;
    const word = n.live ? n.shown : n.status;
    const orchestrated = ui.orch || Boolean(n.labels?.orch);
    const answerable = n.kind === "agent" && n.live && n.status === "blocked" && !orchestrated;
    const meta = [n.app, n.address, n.tab].filter((x, i, all) => x && all.indexOf(x) === i).join(" · ");
    const note = this.noteLine(t);
    const buttons = n.live && n.address ? this.reachButtons(ui, n.address, "act", { tool: n.kind === "tool", primary: true }) : [];
    const keep = n.live && Boolean(n.address) && !n.pane && n.kind !== "ended";
    const keys = {};
    const how = n.live && n.address ? ui.reach(n.address) : null;
    if (how === "focus") keys.f = () => this.focusTerm(n.address, n.kind === "tool");
    if (how === "peek") keys.p = () => this.peek(n.address);
    if (answerable) keys.a = () => this.answer.focus();
    this.shownDetail = { kind: "terminal", node: n, answerable, orch: ui.orch ? ui.root.address : null, keys,
      hint: [how === "focus" ? "f focuses" : how === "peek" ? "p peeks" : "", answerable ? "a answers" : ""].filter(Boolean).join(" · ") };
    return v_flex().id("fleet-detail").min_h(0).bg(solo ? t.canvas : t.popover)
      .when(!solo, (el) => el.child(this.bar(ui, n.name)))
      .child(v_flex().id("detail-body").flex_1().min_h(0).min_w(0).overflow_y_scrollbar().px(16).pt(14).pb(20).gap(14)
        .child(h_flex().gap(10).items_start()
          .child(tile(t, n.program, 28))
          .child(v_flex().flex_1().min_w(0).gap(2)
            .child(div().min_w(0).truncate().text_size(NAME).font_semibold().child(n.name))
            .child(div().min_w(0).truncate().text_size(META).text_color(t.muted).child(meta)))
          .child(badge(t, word, agentWord(word), n.live && since > 0 ? took(since, now) : "")))
        .child(div().text_size(BODY).line_height("19px").text_color(n.report ? t.foreground : t.muted)
          .child(n.report ? firstLine(n.report) : n.live ? "No report yet." : "Its terminal has ended."))
        .when(buttons.length > 0 || keep, (el) => el.child(h_flex().gap(8).flex_wrap()
          .children(buttons)
          .when(keep, (r) => r.child(button(t, "act-keep", "Keep", { h: 24, onClick: (cx) => { run("terminal.keep", { terminal: n.address }); this.note = { text: "Kept: it gets a pane in its parent's tab.", error: false }; cx.notify(); } })))))
        .when(answerable, (el) => el.child(v_flex().gap(6)
          .child(this.answerRow(t, "act-send"))
          .child(div().text_size(META).line_height("16px").text_color(t.muted).child("Types into this agent's dialog."))))
        .when(n.kind === "agent" && n.live && n.status === "blocked" && orchestrated, (el) => el.child(div().text_size(META)
          .line_height("16px").text_color(t.muted).child("Waiting on the orchestrator: it answers its workers' prompts.")))
        .when(Boolean(note), (el) => el.child(note ?? div())));
  }
}
