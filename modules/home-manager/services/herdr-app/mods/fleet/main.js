// Agent Fleet: every reporting agent as a card, most urgent first. One card's tree is open at a time: its
// sub-agents, tools and tasks branch to the right (below it when narrow) on connector lines, and a click on a
// card opens its detail beside the tree (in its place when narrow): bead events, the last screen lines,
// Focus / Peek / Keep / Answer.
// herdr-panda's work area is the stack `work-switch`: the tabs' panes (`work-body`) or the row `fleet`, this block
// and the agent block `fleet-agent` beside it. layout.select shows it, and Esc, fleet.toggle, Back to work, focusing
// an agent or another tab/space shows the work again. Picking an agent shows its live terminal in `fleet-agent`, in
// the frame a worker's or a bead's detail takes.
// The arrows, Enter and Esc also arrive as fleet.<up|down|left|right|enter|escape> commands (keys.json, herdr-app
// do); fleet.fixture / fleet.live switch between sample and live beads.
// Herdr's live data (agents, terminals) redraws it by itself; only live beads poll, every 10 s while it shows.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, terminals, spaces, theme, settings, run, hc, setAgentOrder, checking, window, nextCommand, layout, focused } from "herdr";
import { buildFleet, descendants, STEPS, age } from "./model.js";
import { fixtureEpics } from "./fixtures.js";
import { beadsDir, loadLive } from "./beads.js";

/**
 * @typedef {import("gpui-kit").Context} Cx
 * @typedef {import("gpui-kit").Color} Color
 * @typedef {import("gpui-kit").KeyEvent} KeyEvent
 * @typedef {import("./model.js").FleetNode} Node
 * @typedef {import("./model.js").ShownRoot} ShownRoot
 * @typedef {import("./model.js").Summary} Summary
 * @typedef {import("./model.js").Epic} Epic
 * @typedef {import("./model.js").BeadEvent} BeadEvent
 * @typedef {import("./model.js").Tier} Tier
 * @typedef {Record<string, Color>} Palette
 * @typedef {{ root: number, child: number, detail: number, content: number }} Sizes
 * @typedef {{ t: Palette, now: number, open: string | null, narrow: boolean, size: Sizes, split: boolean, agent: string | null }} Ui
 * @typedef {{ roots: string[], kids: string[], byId: Map<string, Node>, open: string | null }} Nav
 * @typedef {{ id: string, state: "loading" | "ready" | "error" | "none", lines: string[], error?: string }} Screen
 */

const POLL = 10000;
// Below this width the tree goes under its card, and the detail takes the tree's place instead of sitting beside it.
const NARROW = 900;
// The screen tail's rows: a fixed line height, so the block can be sized to them (a scroll area sizes to nothing).
const LINE = 18;
// Below this window width the summary moves under the title, so the header's two ends never collide.
const COMPACT = 1000;
// herdr-panda's work area: the stack, this block's child id in it, and the tabs' panes.
const STACK = "work-switch", SELF = "fleet", WORK = "work-body";
// The layout's agent block beside this one, and the row's gap between them.
const AGENT = "fleet-agent", SPLIT = 8;
// How long a screen read may take before the detail says it's unavailable (ms).
const SCREEN_WAIT = 4000;
// Bead events shown before "Show all".
const EVENTS = 5;
// Connector geometry: the stub from a root to its spine, each child's arm, and where a line meets a card
// (the middle of its icon tile: 11 px padding + 12).
const STUB = 26, ARM = 22, ANCHOR = 23, GAP = 10;
// The type scale: metadata, body, names, titles.
const XS = 11, SM = 12, MD = 13, LG = 15;
const ME = "mods/fleet";

/** What a badge says for each shown state. @type {Record<string, string>} */
const LABEL = {
  working: "Working", supervising: "Supervising", running: "Running", blocked: "Needs you", failed: "Failed",
  done: "Done", idle: "Idle", queued: "Queued", ended: "Ended", sample: "Sample",
};
/** @type {Record<Tier, string>} */
const TIER = { needs: "Needs you", failed: "Failed", working: "Working", done: "Done", idle: "Idle" };

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
/**
 * Card, detail and column widths for a width: a wide work area gets wider cards and a wider detail, not
 * a wider margin. `content` caps the centered column when no detail sits beside it.
 * @param {number} width @returns {Sizes}
 */
const sizesFor = (width) => (width >= 2000 ? { root: 400, child: 440, detail: 900, content: 1600 }
  : width >= 1400 ? { root: 360, child: 380, detail: 620, content: 1320 }
  : { root: 320, child: 300, detail: 460, content: 1180 });
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
    // Whether the last render showed it, and the tab and space it showed over: a change there means the person
    // went to their work, so the work area comes back.
    this.wasShown = false;
    this.where = "";
    // Live beads: the last answer, kept while a refresh runs; error names why bd couldn't answer.
    /** @type {{ byOrch: Map<string, Epic[]> | null, error: string | null, loading: boolean }} */
    this.live = { byOrch: null, error: null, loading: false };
    /** @type {string | null} the login shell's BEADS_DIR, asked once */
    this.beadsDir = null;
    this.fixtureAt = Date.now();
    /** @type {string | null} the root whose tree shows (null: the fleet's default) */
    this.open = null;
    /** @type {string | null} the keyboard's card */
    this.cursor = null;
    /** @type {string | null} the card whose detail shows */
    this.detail = null;
    /** @type {Node | null} */
    this.detailNode = null;
    /** @type {Screen | null} */
    this.screen = null;
    /** @type {string | null} the agent whose live terminal shows beside the tree */
    this.agentFor = null;
    // When this copy last moved the focus (agent.focus picks the agent's own space and tab): not a move to the work.
    this.movedAt = 0;
    // The side frame's width, and the agent block's as last set (the layout file's until then).
    this.sideW = 0;
    this.agentPx = 620;
    // The whole row's width, this block's and the agent block's: measured only when a size change lands, so a
    // frame where the agent block has come or gone but this block's size hasn't followed yet draws the same.
    this.full = 1400;
    /** @type {string | null} the detail kept in the side frame until the agent block takes it */
    this.keepDetail = null;
    // Whether the last render had room for the side frame.
    this.split = true;
    /** @type {Set<number>} expanded events, by position */
    this.expanded = new Set();
    this.allEvents = false;
    /** @type {{ text: string, error: boolean } | null} what the last action said */
    this.note = null;
    this.width = 1400;
    /** @type {string} */
    this.orderKey = "";
    /** @type {Nav} what the last render drew, for keys and commands */
    this.nav = { roots: [], kids: [], byId: new Map(), open: null };
    this.typing = false;
    this.sending = false;
    this.keys = cx.focus_handle();
    this.answer = InputState.new({ placeholder: "Answer this agent…" });
    this.answer.on("submit", (_e, cx) => this.send(cx));
    this.answer.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.answer.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    if (checking()) return;
    // A fresh copy starts without an agent beside it.
    run("layout.hide", { id: AGENT });
    if (this.isShown()) this.loadBeads(cx);
    // A hidden copy keeps running (the stack's other child, another tab): poll only while this one shows.
    cx.timer.every(POLL, (cx) => { if (this.mode === "live" && window()?.visible && this.isShown()) this.loadBeads(cx); });
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "fixture" || c === "live") this.setMode(c, cx);
        else if (c === "toggle") this.toggle();
        else if (c === "focus") this.keys.focus();
        else if (this.walk(c, cx)) cx.notify();
      }
    });
  }

  /** Whether its stack has it selected. */
  isShown() {
    return findNode(layout(), STACK)?.active === SELF;
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

  // Back to the work: the stack shows the tabs' panes again. (Not View's close(cx) hook, which Herdr calls as a
  // copy goes.)
  dismiss() {
    this.hideAgent();
    this.wasShown = false;
    run("layout.select", { stack: STACK, child: WORK });
  }

  /** fleet.toggle: back to the work when showing, else shows itself. */
  toggle() {
    if (!this.isShown()) run("layout.select", { stack: STACK, child: SELF });
    else this.dismiss();
  }

  /** Whether the agent block beside this one shows. */
  agentShown() {
    const n = findNode(layout(), AGENT);
    return Boolean(n) && n?.hidden !== true;
  }

  /** An agent's live terminal in the side frame, in place of a detail. agent.focus picks its space and tab too.
   * @param {Node} node @param {Cx} cx */
  showAgent(node, cx) {
    this.keepDetail = this.detail;
    this.detail = null;
    this.agentFor = node.id;
    this.movedAt = Date.now();
    this.agentPx = this.sideW;
    run("layout.resize", { id: AGENT, px: this.sideW });
    run("layout.show", { id: AGENT });
    run("agent.focus", { terminal: node.address });
    // The keyboard stays on the tree; Enter on the same card moves it into the terminal.
    cx.timer.after(60, () => { if (!this.typing) this.keys.focus(); });
    cx.notify();
  }

  hideAgent() {
    if (this.agentFor === null && !this.agentShown()) return;
    this.agentFor = null;
    run("layout.hide", { id: AGENT });
  }

  /** Shows a card's detail and reads its screen; `answer` puts the keyboard in the answer field.
   * @param {Node} node @param {Cx} cx @param {boolean} [answer] */
  openDetail(node, cx, answer = false) {
    this.hideAgent();
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

  /** Goes to the terminal: the work area comes back first so the focused pane shows.
   * @param {Node} node */
  focus(node) {
    this.dismiss();
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
   * Arrows walk the cards: up/down within the roots or the open tree, right into a tree, left back out.
   * Enter opens a root's tree, then a card's detail (with the answer field, for one that needs you); on a card
   * whose detail shows, it focuses that terminal. Esc closes the detail, then the fleet. Answers whether the
   * key was one of these.
   * @param {string} key @param {Cx} cx
   */
  walk(key, cx) {
    if (key === "escape") {
      if (this.detail) this.detail = null; else if (this.agentFor) this.hideAgent(); else this.dismiss();
      return true;
    }
    if (!["up", "down", "left", "right", "enter"].includes(key)) return false;
    const { roots, kids, byId, open } = this.nav;
    const at = this.cursor && byId.has(this.cursor) ? this.cursor : open;
    const node = at ? byId.get(at) : undefined;
    if (!at || !node) return true;
    const inRoots = roots.includes(at);
    const list = inRoots ? roots : kids;
    const i = list.indexOf(at);
    if (key === "up" || key === "down") this.cursor = list[Math.max(0, Math.min(list.length - 1, i + (key === "down" ? 1 : -1)))] ?? at;
    else if (key === "right" && inRoots) {
      this.open = at;
      this.detail = null;
      this.cursor = descendants(node)[0]?.id ?? at;
    } else if (key === "left" && !inRoots) { this.cursor = open; this.detail = null; }
    else if (key === "enter") {
      if (inRoots && this.split && node.live && node.address) {
        this.open = at;
        if (this.agentFor === at) this.focus(node); else this.showAgent(node, cx);
      } else if (inRoots && at !== open) { this.open = at; this.detail = null; this.cursor = at; }
      else if (this.detail === at && node.address && node.live) this.focus(node);
      else this.openDetail(node, cx, node.status === "blocked");
    }
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
    const key = fleet.order.join(",");
    if (key !== this.orderKey) { this.orderKey = key; setAgentOrder(fleet.order); }

    const roots = fleet.roots;
    const open = roots.some((r) => r.node.id === this.open) ? this.open : fleet.defaultOpen;
    const byId = new Map(roots.flatMap((r) => [r.node, ...descendants(r.node)]).map((n) => [n.id, n]));
    const openRoot = open ? byId.get(open) : undefined;
    const kids = openRoot ? descendants(openRoot).map((n) => n.id) : [];
    const shown = this.detail ? byId.get(this.detail) ?? null : null;
    this.detailNode = shown;
    this.nav = { roots: roots.map((r) => r.node.id), kids, byId, open };
    // Showing anew, take the keyboard (the hidden work area's terminal had it) and refresh live beads.
    // Another tab or space while showing means the person went to their work: show it. Not when this copy just
    // moved there itself, showing an agent.
    const visible = this.isShown() && !checking();
    const f = focused(), where = `${f?.space ?? ""}|${f?.tab ?? ""}`;
    if (visible && !this.wasShown) cx.timer.after(0, (cx) => {
      if (!this.typing) this.keys.focus();
      if (this.mode === "live") this.loadBeads(cx);
    });
    else if (visible && where !== this.where && now - this.movedAt > 3000) cx.timer.after(0, () => this.dismiss());
    this.wasShown = visible;
    this.where = where;

    // Two frames side by side: the fleet (header, tree, footer) and a side frame for the picked card, the same
    // size whatever is picked. An agent's side frame is the layout's agent block, beside this block, which is
    // narrower by that much then; a worker's or a bead's is drawn here. Too narrow for both: the detail takes the
    // tree's place, with a way back, and an agent's terminal isn't shown. Every width comes from the whole row
    // (this.full), so switching between the two draws nothing in between.
    const laidOut = this.agentShown();
    // Right after showAgent the layout may not say so yet: trust this copy for a second, then the layout (a hidden
    // block or an agent gone ends it).
    const fresh = now - this.movedAt < 1000;
    if (this.agentFor !== null && !(byId.has(this.agentFor) && (fresh || laidOut))) this.agentFor = null;
    const full = this.full;
    const size = sizesFor(full);
    // The tree column fits the deepest tree in the fleet (one level of workers at least), not the open one, so
    // picking an agent without workers doesn't shrink it.
    const depth = Math.max(1, ...roots.map((r) => depthOf(r.node)));
    const treeW = size.root + STUB + ARM + size.child + (depth - 1) * (16 + ARM) + 48;
    const sideW = Math.min(size.detail, full - treeW - SPLIT);
    const split = sideW >= 400;
    this.split = split;
    if (split) this.sideW = sideW;
    if (split && sideW !== this.agentPx) {
      this.agentPx = sideW;
      run("layout.resize", { id: AGENT, px: sideW });
    }
    if (!split && (this.agentFor !== null || laidOut)) cx.timer.after(0, () => this.hideAgent());
    const agent = split ? this.agentFor : null;
    if (agent === null || laidOut) this.keepDetail = null;
    // Until the agent block shows, the side frame keeps what it had.
    const side = shown ?? (agent !== null && this.keepDetail ? byId.get(this.keepDetail) ?? null : null);
    const replace = !split && Boolean(shown);
    /** @type {Ui} */
    const ui = { t, now, open, size, narrow: !split && full < NARROW, split, agent };
    const list = () => v_flex().id("fleet-body").flex_1().h_full().min_w(0).overflow_y_scrollbar().px(24).pt(18).pb(32)
      .child(v_flex().w_full().max_w(split ? treeW - 48 : size.content).mx_auto().gap(10)
        .when(roots.length === 0, (b) => b.child(this.empty(t)))
        .children(roots.flatMap((r, i) => [
          ...(i === 0 || roots[i - 1].tier !== r.tier ? [this.tierHeading(t, r.tier, roots.filter((x) => x.tier === r.tier).length, i > 0)] : []),
          this.rootRow(ui, r),
        ])));
    const frame = () => v_flex().h_full().min_h(0).rounded(10).border_1().border_color(t.border).overflow_hidden();

    return h_flex().id("fleet").track_focus(this.keys).on_key_down((e, cx) => this.onKey(e, cx))
      .on_size_change((sz, cx) => {
        const row = sz.width + (this.agentShown() ? this.agentPx + SPLIT : 0);
        this.width = sz.width;
        if (Math.abs(row - this.full) > 1) { this.full = row; cx.notify(); }
      })
      .size_full().gap(SPLIT).overflow_hidden().text_color(t.foreground).text_size(MD)
      .child(frame().when(split, (el) => el.w(full - sideW - SPLIT).flex_none()).when(!split, (el) => el.flex_1()).min_w(0).bg(t.canvas)
        .child(this.header(t, fleet.summary, this.beadsWarning(), (split ? full - sideW - SPLIT : this.width) < COMPACT))
        .child(h_flex().flex_1().min_h(0).items_start()
          .when(replace && Boolean(shown), (el) => (shown ? el.child(this.detailPanel(ui, shown, true).flex_1().min_w(0).h_full()) : el))
          .when(!replace, (el) => el.child(list())))
        .child(this.footer(t)))
      .when(split && !laidOut, (el) => el.child(frame().w(sideW).flex_none().bg(t.popover)
        .child(side ? this.detailPanel(ui, side, false).size_full() : this.inspectorHint(t))));
  }

  /** The inspector before a card is picked: what it will show and how to pick one. @param {Palette} t */
  inspectorHint(t) {
    return v_flex().id("fleet-detail-hint").p(20).gap(6)
      .child(div().text_size(MD).font_medium().text_color(t.foreground).child("No card picked"))
      .child(div().text_size(SM).line_height("18px").text_color(t.muted)
        .child("Pick an agent to work in its terminal here, or a worker or task to see its bead events, its last screen lines and Focus, Peek, Keep and Answer."));
  }

  /** Title and summary, then what's off about beads (or that the beads are a sample), and close. Compact: the
   * summary on a second row. @param {Palette} t @param {Summary} s @param {string | null} warning @param {boolean} compact */
  header(t, s, warning, compact) {
    /** @param {number} n @param {string} one @param {string} many */
    const plural = (n, one, many) => `${n} ${n === 1 ? one : many}`;
    /** @param {string} text @param {Color} [color] */
    const count = (text, color) => div().text_color(color ?? t.muted).child(text);
    const parts = [
      count(`${plural(s.agents, "agent", "agents")} / ${plural(s.subAgents, "sub-agent", "sub-agents")}`),
      count(`${s.working} working`, s.working ? t.foreground : t.muted),
      count(`${s.needs} ${s.needs === 1 ? "needs" : "need"} you`, s.needs ? t.blocked : t.muted),
      ...(s.failed ? [count(`${s.failed} failed`, this.color(t, "failed"))] : []),
      ...(s.tasks ? [count(`${s.finished}/${s.tasks} tasks done`)] : []),
    ].flatMap((el, i) => (i ? [div().text_color(t.dim).child("·"), el] : [el]));
    const summary = h_flex().gap(7).items_center().text_size(SM).whitespace_nowrap().children(parts);
    const reading = this.mode === "live" && !this.live.byOrch && !this.live.error;
    const top = h_flex().h(compact ? 46 : 52).flex_none().gap(14).items_center()
      .child(div().flex_none().text_size(LG).font_semibold().child("Agent Fleet"))
      .when(!compact, (el) => el.child(summary))
      .child(div().flex_1())
      .when(this.mode === "fixture", (el) => el.child(div().id("sample-chip").h(22).px(8).flex().flex_none().items_center().rounded(5)
        .border_1().border_color(t.input).bg(t.raised).text_size(XS).font_medium().text_color(t.foreground)
        .tooltip("Beads here are a made-up sample (fleet.live for real ones)").child("Sample data")))
      .when(reading, (el) => el.child(div().text_size(XS).text_color(t.muted).child("Reading beads…")))
      .when(Boolean(warning), (el) => el.child(h_flex().id("beads-warning").min_w(0).max_w(560).gap(6).items_center()
        .text_size(SM).text_color(t.blocked).tooltip(warning ?? "")
        .child(svg(`${ME}/alert.svg`).size(13).flex_none().text_color(t.blocked))
        .child(div().min_w(0).truncate().child(warning ?? ""))))
      .child(h_flex().id("fleet-back").h(28).px(10).gap(6).flex_none().items_center().rounded(6)
        .border_1().border_color(t.input).bg(t.raised).cursor_pointer().role("button").accessibility_label("Back to work")
        .tooltip("Back to the tabs' panes (Esc)").text_size(SM).font_medium().text_color(t.foreground)
        .hover((st) => st.bg(t.hover)).on_click(() => this.dismiss())
        .child(svg("mods/workspace-chrome/chevron-left.svg").size(14).flex_none().text_color(t.muted)).child("Back to work"));
    return v_flex().id("fleet-header").flex_none().px(20).border_b_1().border_color(t.border).bg(t.chrome)
      .child(top).when(compact, (el) => el.child(h_flex().h(28).pb(8).items_center().child(summary)));
  }

  /** The keys, and which beads database the live view reads. @param {Palette} t */
  footer(t) {
    return h_flex().id("fleet-footer").h(30).flex_none().px(20).gap(16).items_center().border_t_1().border_color(t.border)
      .bg(t.chrome).text_size(XS).text_color(t.muted)
      .child(div().flex_none().child(`↑↓←→ move · Enter open, again to go to it · Esc ${this.detail || this.agentFor ? "close" : "back to work"}`))
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

  /** @param {Palette} t @param {Tier} tier @param {number} n @param {boolean} spaced */
  tierHeading(t, tier, n, spaced) {
    return h_flex().gap(8).items_center().text_size(SM).when(spaced, (el) => el.mt(12))
      .child(div().font_medium().text_color(t.muted).child(TIER[tier]))
      .child(div().text_size(XS).text_color(t.muted).child(String(n)))
      .child(div().flex_1().h(1).bg(t.border));
  }

  /** @param {Ui} ui @param {ShownRoot} r */
  rootRow(ui, r) {
    const { t, open, narrow } = ui;
    const isOpen = r.node.id === open;
    const card = this.card(ui, r.node, r, !isOpen);
    const kids = r.node.children;
    // Said once for the tree, not on every card: workers no bead names, or an orchestrator with no epic.
    const noEpic = this.mode === "live" && r.orch && r.node.address && this.live.byOrch?.get(r.node.address)?.length === 0;
    const note = r.rollup.unbeaded ? `${r.rollup.unbeaded} ${r.rollup.unbeaded === 1 ? "worker has" : "workers have"} no bead`
      : noEpic ? "No open epic for this session" : null;
    const left = v_flex().flex_none().gap(6).child(card)
      .when(isOpen && Boolean(note), (el) => el.child(div().pl(12).text_size(XS).text_color(t.muted).child(note ?? "")));
    if (!isOpen || !kids.length) return h_flex().items_start().child(left);
    if (narrow) return v_flex().items_start().child(left).child(div().pl(18).child(this.branch(ui, kids, "top")));
    // The open root's line leaves its right edge from a small ring and meets the spine.
    const stub = div().relative().w(STUB).h(ANCHOR * 2).flex_none()
      .child(div().absolute().top(ANCHOR).left(0).w(STUB).h(1).bg(t.accent))
      .child(div().absolute().top(ANCHOR - 3).left(-4).size(7).rounded_full().border_1().border_color(t.accent).bg(t.canvas));
    return h_flex().items_start().child(left).child(stub).child(this.branch(ui, kids, "side"));
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
          .child(this.card(ui, n, null, false))
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

  /** A card: a root (with its rollup, dimmed while another root is open) or a child. @param {Ui} ui @param {Node} n
   * @param {ShownRoot | null} root @param {boolean} dim */
  card(ui, n, root, dim) {
    const { t, now } = ui;
    const cursor = this.cursor === n.id, shown = this.detail === n.id || ui.agent === n.id;
    const since = ageLabel(n, now);
    const meta = (root ? [n.app, n.address, root.space] : n.bead ? [n.bead.id, n.address] : [n.app, n.address])
      .filter((x, i, all) => x && all.indexOf(x) === i).join(" · ");
    const kids = n.children.length;
    const answer = !root && n.status === "blocked" && answerable(n);
    const r = root?.rollup;
    const mark = !r ? "idle" : r.needs ? "blocked" : r.failed ? "failed" : r.working ? "running" : "idle";
    const foot = r ? r.text : kids ? `${kids} under it` : null;
    return v_flex().id(`card-${n.id}`).w(root ? ui.size.root : ui.size.child).flex_none().px(12).pt(11).pb(10).gap(7).rounded(12)
      .bg(shown ? t.selected : t.background).border_1()
      .border_color(cursor ? t.accent : root && !dim ? t.input : t.border)
      .when(n.status === "queued", (el) => el.border_dashed())
      .opacity(dim ? 0.7 : 1).transition("opacity", 160)
      .cursor_pointer().hover((s) => s.border_color(cursor ? t.accent : t.input))
      .role("button").accessibility_label(`${n.name}, ${LABEL[n.shown] ?? n.shown}`)
      .on_click((_e, cx) => {
        this.cursor = n.id;
        this.keys.focus();
        // An agent shows its live terminal beside the tree (again: goes to it); else, narrow, the first click opens
        // its tree. A worker or a bead shows its detail.
        if (root && ui.split && n.live && n.address) {
          this.open = n.id;
          if (ui.agent === n.id) this.focus(n); else this.showAgent(n, cx);
        } else if (root && ui.open !== n.id) { this.open = n.id; this.detail = null; cx.notify(); }
        else this.openDetail(n, cx);
      })
      .child(h_flex().gap(9).items_start()
        .child(this.tile(t, n))
        .child(v_flex().flex_1().min_w(0).gap(1)
          .child(h_flex().gap(8).items_center()
            .child(div().flex_1().min_w(0).text_size(MD).font_medium().truncate().child(n.name))
            .child(this.badge(t, n)))
          .child(h_flex().gap(8).text_size(XS).text_color(t.muted)
            .child(div().flex_1().min_w(0).truncate().child(meta))
            .when(!root && Boolean(since), (m) => m.child(div().flex_none().child(since ?? ""))))))
      .when(Boolean(n.task), (el) => el.child(div().text_size(SM).text_color(t.muted).truncate().child(n.task)))
      .when(Boolean(n.life), (el) => (n.life ? el.child(this.strip(t, n, n.life, false)) : el))
      .when(Boolean(foot || answer || (root && since)), (el) => el.child(h_flex().gap(8).items_center().text_size(XS)
        .when(Boolean(r), (f) => f.child(this.glyph(mark, this.color(t, mark === "running" ? "working" : mark === "idle" ? "ended" : mark))))
        .child(div().flex_1().min_w(0).truncate().text_color(r?.needs ? t.foreground : t.muted).child(foot ?? ""))
        .when(Boolean(root && since), (f) => f.child(div().flex_none().text_color(t.muted).child(since ?? "")))
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
          .role("button").accessibility_label("Back to the fleet").text_size(SM).text_color(t.muted)
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
