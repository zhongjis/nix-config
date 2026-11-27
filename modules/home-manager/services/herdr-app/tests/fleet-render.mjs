// The Agents panel (mods/fleet/main.js) rendered against stand-ins for gpui and herdr: a shared "fleet.open" opens its
// task whatever agent is focused, without cx.notify() during render; the detail has no screen preview and its session
// rows offer Peek (no pane), Focus (a pane on another tab) or nothing (on screen); Send checks the live question and
// names it; Esc closes; Ctrl/Cmd+Shift+A passes through to the app. Made-up data only.
// Run: node --experimental-vm-modules modules/home-manager/services/herdr-app/tests/fleet-render.mjs
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

// ----- stand-ins ---------------------------------------------------------------------------------------------------
// A gpui element: records its id, children, handlers, whether it scrolls and its max height; every other builder call
// returns it.
function element() {
  const node = { key: null, items: [], handlers: {}, scrolls: false, maxH: null };
  const proxy = new Proxy(node, {
    get(target, key) {
      if (key === Symbol.toPrimitive) return () => 0;
      if (key in target) return target[key];
      return (...args) => {
        if (key === "when") { if (args[0]) args[1](proxy); } else if (key === "child") node.items.push(args[0]);
        else if (key === "children") node.items.push(...args[0]);
        else if (key === "id") node.key = args[0];
        else if (key === "overflow_y_scrollbar" || key === "overflow_scrollbar" || key === "overflow_y_scroll") node.scrolls = true;
        else if (key === "max_h") node.maxH = args[0];
        else if (String(key).startsWith("on_")) node.handlers[key] = args.at(-1);
        return proxy;
      };
    },
  });
  return proxy;
}
const find = (node, id) => {
  if (!node || typeof node !== "object") return null;
  if (node.key === id) return node;
  for (const c of node.items ?? []) { const hit = find(c, id); if (hit) return hit; }
  return null;
};
const scrollers = (node) => (!node || typeof node !== "object" ? [] : [...(node.scrolls ? [node] : []), ...(node.items ?? []).flatMap(scrollers)]);
const ids = (node) => (!node || typeof node !== "object" ? [] : [...(node.key ? [node.key] : []), ...(node.items ?? []).flatMap(ids)]);
const texts = (node) => (typeof node === "string" ? [node] : node && typeof node === "object" ? (node.items ?? []).flatMap(texts) : []);

const now = Date.parse("2026-01-01T12:00:00Z");
const iso = (min) => new Date(now + min * 60000).toISOString();
const w = {
  shared: {}, focused: { agent: "X", tab: "tab-1" }, runs: [], hc: [], notes: [], bd: [],
  agents: [], terminals: [], panes: [], liveQuestion: "c-q2",
};
let inRender = false, notifies = 0;
const jobs = [], timers = [];
const cx = {
  notify() { if (inRender) throw new Error("cx.notify() during render"); notifies++; },
  spawn: (fn) => { jobs.push(fn); },
  timer: { every: () => ({}), after: (ms, fn) => { timers.push([ms, fn]); return { cancel() {} }; } },
  focus_handle: () => ({ focus() {}, is_focused: () => false }),
  stop_propagation() { cx.stopped = true; },
  open_url(url) { w.runs.push(["open_url", url]); },
};
const drain = async () => { while (jobs.length) await jobs.shift()(cx); };
// Every scroll handle records the items it was asked to reveal.
const scrolledTo = [];
const scroll = () => ({ offset: () => ({ x: 0, y: 0 }), viewport_size: () => ({ width: 0, height: 0 }), content_size: () => ({ width: 0, height: 0 }),
  scroll_to_item(i) { scrolledTo.push(i); } });
let answerText = "";
const inputOn = {};
const input = { on(ev, fn) { inputOn[ev] = fn; }, value: () => answerText, set_value(v) { answerText = v; }, focus() {} };
const type = (text) => { answerText = text; inputOn.change?.({}, cx); };
const layoutTree = { id: "root", children: [{ id: "panel", hidden: false, children: [] }, { id: "panel-body", active: "fleet", children: [] }] };

// The bead the answer is checked against, as `bd show <id> --include-comments --json` gives it.
const bdShow = (id) => [{ id, status: "in_progress", metadata: { blocked_reason: "needs-user" }, comments: [
  { id: "c-q1", text: "event=blocked reason=needs-user\n\nOld question?", created_at: iso(-30), author: "o-O" },
  { id: w.liveQuestion, text: "event=blocked reason=needs-user\n\nKeep 30 or 90 days?", created_at: iso(-20), author: "o-O" },
] }];
const herdr = {
  agents: () => w.agents, terminals: () => w.terminals, spaces: () => [{ id: "s1", name: "repo", tabs: [{ id: "tab-1", name: "one" }, { id: "tab-2", name: "two" }] }],
  panes: () => w.panes, focused: () => w.focused, layout: () => layoutTree, window: () => ({ visible: true, active: true, platform: "linux" }),
  shared: (k) => w.shared[k] ?? null, setShared: (k, v) => { w.shared[k] = v; }, run: (...a) => { w.runs.push(a); return null; },
  notify: (n) => w.notes.push(n), checking: () => false, nextCommand: () => new Promise(() => {}),
  theme: () => ({ foreground: "#ffffff", background: "#000000", muted: "#aaaaaa", blocked: "#ff0000", accent: "#0000ff", working: "#00ff00",
    done: "#00aa00", border: "#333333", input: "#444444", raised: "#222222", canvas: "#111111", chrome: "#111111", popover: "#111111",
    selected: "#222222", hover: "#333333", solid: "#ffffff", solid_foreground: "#000000", idle: "#888888", dim: "#666666", unknown: "#777777" }),
  settings: () => ({ font_family: "Mono" }),
  hc: async (args) => { w.hc.push(args); return { code: 0, stdout: "", stderr: "" }; },
  exec: async (cmd, args) => {
    const argv = cmd === "/usr/bin/env" ? args.slice(2) : args;
    w.bd.push(argv);
    if (argv[0] === "show") return { code: 0, stdout: JSON.stringify(bdShow(argv[1])), stderr: "" };
    return { code: 0, stdout: "[]", stderr: "" };
  },
};
const gpui = { View: class {}, div: element, svg: element, image: element };
const base = { v_flex: element, h_flex: element, Input: { new: () => element() }, InputState: { new: () => input }, ScrollHandle: { new: scroll } };

const context = vm.createContext({ console, Date, JSON, Math, Promise, Map, Set, WeakMap, Number, String, Object, Array, Error, URL, RegExp });
const synth = (exports) => new vm.SyntheticModule(Object.keys(exports), function () { for (const [k, v] of Object.entries(exports)) this.setExport(k, v); }, { context });
const natives = { herdr: synth(herdr), "gpui-kit": synth(gpui), "gpui-base": synth(base) };
const cache = new Map();
async function load(url) {
  if (!cache.has(url.href)) cache.set(url.href, new vm.SourceTextModule(await readFile(url, "utf8"), { context, identifier: url.href }));
  return cache.get(url.href);
}
const main = await load(new URL("../mods/fleet/main.js", import.meta.url));
await main.link((name, parent) => natives[name] ?? load(new URL(name, parent.identifier)));
await main.evaluate();
const Fleet = main.namespace.default;

// ----- the world: orchestrator O (pane on tab-1), worker W2 (no pane), reviewer R2 (pane on tab-1), worker W3 (pane on tab-2)
const agent = (address, status, tab, extra = {}) => ({ address, status, tab, tab_name: tab, space: "s1", space_name: "repo", title: address, ...extra });
w.agents = [agent("O", "idle", "tab-1", { pane_name: "[o] ship it" }), agent("X", "idle", "tab-1"), agent("R2", "working", "tab-1"), agent("W3", "working", "tab-2")];
w.terminals = [
  { address: "O", state: "live", status: "idle", labels: {} },
  { address: "X", state: "live", status: "idle", labels: {} },
  { address: "W2", name: "w-abc-2", parent: "O", state: "live", status: "idle", labels: { orch: "O" } },
  { address: "R2", name: "r-abc-2", parent: "O", state: "live", status: "working", labels: { orch: "O" } },
  { address: "W3", name: "w-abc-3", parent: "O", state: "live", status: "working", labels: { orch: "O" } },
];
w.panes = [{ pane: "p-O", terminal: "O", tab: "tab-1" }, { pane: "p-X", terminal: "X", tab: "tab-1" }, { pane: "p-R2", terminal: "R2", tab: "tab-1" },
  { pane: "p-W3", terminal: "W3", tab: "tab-2" }];
const c = (id, text, min, author = "o-O") => ({ id, text, created_at: iso(min), author });
const session = {
  epic: { id: "e1", created_at: iso(-100), metadata: { session: "O" } },
  mode: null,
  beads: [
    { id: "b2", title: "Two", status: "in_progress", assignee: "w-abc-2", external_ref: "https://tracker.example/browse/ABC-2", metadata: { blocked_reason: "needs-user", review_round: "1" } },
    { id: "b3", title: "Three", status: "in_progress", assignee: "w-abc-3", metadata: {} },
  ],
  deps: {},
  reviews: { b2: [{ id: "rv2", title: "Review b2 round 1", assignee: "r-abc-2", status: "in_progress", metadata: {} },
    { id: "rv2b", title: "Review b2 round 1 (agy)", assignee: "r-abc-2-agy", status: "closed", metadata: {} }] },
  comments: {
    b2: [c("c-d", "event=dispatched agent=w-abc-2 terminal=W2", -60), c("c-q2", "event=blocked reason=needs-user\n\nKeep 30 or 90 days?", -20)],
    b3: [c("c-d3", "event=dispatched agent=w-abc-3 terminal=W3", -60)],
    rv2: [c("c-r", "event=dispatched agent=r-abc-2 terminal=R2", -40), c("c-rr", "event=report kind=done", -30, "r-abc-2")],
  },
};

const fleet = new Fleet();
fleet.init({}, cx);
jobs.length = 0; // init's command loop waits on nextCommand() forever: not under test
fleet.data.set("O", { session, extra: 0, error: null, at: now });
fleet.beadsDir = "/beads";
fleet.askedFor = "O"; fleet.wasShown = true;
const render = () => { inRender = true; try { return fleet.render(cx); } finally { inRender = false; } };

// Another agent (X) has the focus; a fleet.open for O's task b2 arrives.
w.shared["fleet.open"] = { orch: "O", epic: "e1", bead: "b2", at: Date.now() };
let tree = render();
assert.equal(fleet.openId, "b2", "the named task is open, though X is focused");
assert.equal(fleet.selAddr, "O");
assert.ok(find(tree, "fleet-detail"), "its detail draws (narrow: in place of the tree)");
assert.equal(notifies, 0, "nothing notified during render");
// No screen preview, and no screen reads.
assert.ok(!ids(tree).some((id) => /^(screen|sk-|ln-|screen-retry)/.test(String(id))));
assert.ok(!w.hc.some((a) => a[0] === "read"));
// Session rows: the hidden worker gets Peek only; the reviewer on screen gets neither.
assert.ok(find(tree, "peek-w-b2") && !find(tree, "focus-w-b2"));
assert.ok(!find(tree, "peek-r1-b2") && !find(tree, "focus-r1-b2"));
// Two parallel reviewers of round 1 each name themselves (the one with a terminal has a session row).
assert.ok(texts(tree).includes("Review r1 · r-abc-2 · in_progress"));
// The question and its answer field; the reviewer's report shows in the timeline.
assert.ok(texts(tree).includes("Keep 30 or 90 days?"));
assert.ok(find(tree, "act-send"));

// A later render with the same request does nothing new; focus moving to another agent ends the pin.
render();
assert.equal(fleet.openId, "b2");
w.focused = { agent: "W3", tab: "tab-1" };
tree = render();
assert.equal(fleet.selAddr, "O", "W3 is under O: still O");
w.focused = { agent: "X", tab: "tab-1" };
render();
assert.equal(fleet.selAddr, "X", "the focus moved on: the panel follows it again");
assert.equal(fleet.openId, null);

// Back on O's task; Send names the question it answers, checked against the bead now.
w.focused = { agent: "O", tab: "tab-1" };
render();
fleet.open("b2", cx);
tree = render();
answerText = "90 days";
fleet.submit(cx);
await drain();
const send = w.hc.find((a) => a[0] === "send");
assert.deepEqual(Array.from(send).slice(0, 3), ["send", "--", "O"], "to the orchestrator, after --");
assert.equal(send[3], "Answer from the herdr-app panel for ABC-2 (bead b2, question c-q2). Question: Keep 30 or 90 days?. Answer: 90 days");
assert.ok(w.bd.some((a) => a[0] === "show" && a[1] === "b2" && a.includes("--include-comments")), "the live hold was read first");
// The bead's question changed meanwhile: nothing is sent, and the panel says so.
w.hc.length = 0; w.liveQuestion = "c-q3"; answerText = "30";
fleet.submit(cx);
await drain();
assert.ok(!w.hc.some((a) => a[0] === "send"));
assert.match(fleet.note.text, /answered or replaced/);
assert.ok(w.bd.some((a) => a[0] === "list" && a.includes("session=O")), "and the session is read again");
fleet.data.set("O", { session, extra: 0, error: null, at: now }); // the fake bd has no epics: put the session back

// A draft belongs to the question it was typed under. The question changes: Send refuses until the draft is edited.
render();
type("keep 90");
const q3 = { ...session, comments: { ...session.comments, b2: [...session.comments.b2,
  c("c-q3", "event=blocked reason=needs-user\n\nKeep 60 days instead?", -5)] } };
fleet.data.set("O", { session: q3, extra: 0, error: null, at: now });
tree = render();
assert.ok(texts(tree).includes("This question replaced the one your draft answers. Edit the draft to answer this one."));
w.hc.length = 0;
fleet.submit(cx);
await drain();
assert.ok(!w.hc.some((a) => a[0] === "send"), "a draft for the old question is never sent to the new one");
assert.match(fleet.note.text, /after you typed this/);
type("keep 60"); // edited while the new question shows: now it answers that one
fleet.submit(cx);
await drain();
const resent = w.hc.find((a) => a[0] === "send");
assert.match(resent[3], /\(bead b2, question c-q3\)\. .*Answer: keep 60$/, "names the new question (its text comes from the live read)");
assert.equal(answerText, "", "the sent draft is cleared");
// A send that finishes after the field moved on leaves the newer draft alone.
type("other draft");
w.hc.length = 0;
fleet.submit(cx);
type("typed meanwhile");
await drain();
assert.equal(answerText, "typed meanwhile");
answerText = "";
fleet.data.set("O", { session, extra: 0, error: null, at: now });
w.liveQuestion = "c-q2";

// Keys: Esc closes the detail; Ctrl+Shift+A is not the panel's (the app binding closes it).
cx.stopped = false;
fleet.onKey({ key: "a", modifiers: { control: true, shift: true } }, cx);
assert.equal(cx.stopped, false, "Ctrl+Shift+A passes through");
fleet.onKey({ key: "escape", modifiers: {} }, cx);
assert.equal(cx.stopped, true);
assert.equal(fleet.openId, null);

// The task detail has one scroll area: the timeline's rows, filling what the fixed part leaves (no 360 px cap).
fleet.open("b2", cx);
tree = render();
let areas = scrollers(find(tree, "fleet-detail"));
assert.deepEqual(areas.map((n) => n.key), ["tl-b2"], "only the timeline scrolls");
assert.ok(find(tree, "detail-fixed") && !find(find(tree, "detail-fixed"), "tl-b2"), "the header, sessions and answer stay above it");
assert.ok(find(tree, "act-send"), "the answer field is in the fixed part");
assert.ok(!scrollers(tree).some((n) => n.maxH === 360) && !JSON.stringify(ids(tree)).includes("sk-"));
// Its sizes arrive: a tall panel keeps that; one too short for a 200 px timeline scrolls the whole detail instead.
find(tree, "fleet-detail").handlers.on_size_change({ width: 368, height: 900 }, cx);
find(tree, "detail-fixed").handlers.on_size_change({ width: 368, height: 400 }, cx);
tree = render();
assert.deepEqual(scrollers(find(tree, "fleet-detail")).map((n) => n.key), ["tl-b2"]);
find(tree, "fleet-detail").handlers.on_size_change({ width: 368, height: 560 }, cx);
tree = render();
areas = scrollers(find(tree, "fleet-detail"));
assert.deepEqual(areas.map((n) => n.key), ["detail-body"], "short: one area, the whole detail");
assert.ok(find(find(tree, "detail-body"), "detail-fixed"));
// The end jump waits for the layout to be measured, and a switch between layouts while at the end jumps again in
// the new scroll area (after the fixed part and its spacer when the whole detail scrolls).
fleet.detailH = 0; fleet.fixedH = 0; fleet.tlShort = undefined; fleet.tlAtEnd = undefined;
fleet.closeDetail(); fleet.open("b2", cx);
scrolledTo.length = 0;
tree = render();
assert.deepEqual(scrolledTo, [], "not measured yet: the jump is kept");
find(tree, "fleet-detail").handlers.on_size_change({ width: 368, height: 900 }, cx);
find(tree, "detail-fixed").handlers.on_size_change({ width: 368, height: 400 }, cx);
render();
const last = fleet.tl.last;
assert.deepEqual(scrolledTo, [last], "tall: the newest event in the timeline area");
find(tree, "fleet-detail").handlers.on_size_change({ width: 368, height: 560 }, cx);
tree = render();
assert.deepEqual(scrolledTo, [last, last + 2], "short: the same event, in the whole-detail area");
// Short: no gap between events (the spine stays whole); a 14 px spacer after the fixed part instead.
assert.equal(find(tree, "detail-body").items[1].items.length, 0);
fleet.detailH = 0; fleet.fixedH = 0;
fleet.closeDetail();

// fleet.open waits for a read started after it: an older cached session without the task doesn't drop it.
{
  const reqAt = Date.now();
  const older = { ...session, beads: session.beads.filter((b) => b.id !== "b3") };
  fleet.data.set("O", { session: older, extra: 0, error: null, at: reqAt - 1000, startedAt: reqAt - 2000 });
  w.shared["fleet.open"] = { orch: "O", epic: "e1", bead: "b3", at: reqAt };
  render();
  assert.ok(fleet.pendingOpen, "kept while only an older read is in");
  fleet.data.set("O", { session, extra: 0, error: null, at: reqAt + 2, startedAt: reqAt + 1 });
  render();
  assert.equal(fleet.openId, "b3");
  assert.equal(fleet.pendingOpen, null);
  // A read that started after the request and lacks the task drops it.
  w.shared["fleet.open"] = { orch: "O", epic: "e1", bead: "b9", at: reqAt + 5 };
  fleet.data.set("O", { session, extra: 0, error: null, at: reqAt + 7, startedAt: reqAt + 6 });
  render();
  assert.equal(fleet.pendingOpen, null);
  fleet.closeDetail();
}

// Wide: the detail sits beside the tree; the worker on another tab gets Focus only.
fleet.width = 900;
fleet.open("b3", cx);
tree = render();
assert.ok(find(tree, "fleet-tasks") && find(tree, "fleet-detail"), "tree and detail side by side");
assert.ok(texts(find(tree, "task-b2")).includes("Review r1 · r-abc-2-agy · closed"), "the card lists both parallel reviewers by name");
assert.ok(texts(find(tree, "task-b2")).includes("Review r1 · r-abc-2 · in_progress"));
assert.ok(find(tree, "focus-w-b3") && !find(tree, "peek-w-b3"));
// Its keys: f focuses the worker, as its row offers.
w.runs.length = 0;
fleet.onKey({ key: "f", modifiers: {} }, cx);
assert.deepEqual(JSON.parse(JSON.stringify(w.runs)), [["agent.focus", { terminal: "W3" }]]);

// Parallel reviewers' buttons have their own ids: the reviewer's pane on another tab gets Focus, named by reviewer.
w.focused = { agent: "O", tab: "tab-2" };
fleet.width = 368;
fleet.open("b2", cx);
tree = render();
assert.ok(find(tree, "focus-r1-r-abc-2-b2"), "the id names the reviewer");

console.log("fleet-render: ok");
