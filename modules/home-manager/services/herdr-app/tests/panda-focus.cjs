// panda-focus checks: settled agents retire on every settle, "closing" shows only while exiting, snooze, reboot resumes,
// hibernated workers keep their identity, orchestrator summaries, the ticker and the keys.
// Run: nix shell nixpkgs#nodejs --command node --test modules/home-manager/services/herdr-app/tests/panda-focus.cjs
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { test } = require("node:test");

const dir = path.join(__dirname, "../mods/panda-focus");

// A stand-in for gpui elements: records ids, children, handlers.
function element() {
  const node = { key: null, items: [], handlers: {} };
  const proxy = new Proxy(node, { get(target, key) {
    if (key in target) return target[key];
    return (...args) => {
      if (key === "when") { if (args[0]) args[1](proxy); }
      else if (key === "child") node.items.push(args[0]);
      else if (key === "children") node.items.push(...args[0]);
      else if (key === "id") node.key = args[0];
      else if (key.startsWith("on_")) node.handlers[key === "on_mouse_down" ? `${key}:${args[0]}` : key] = args.at(-1);
      return proxy;
    };
  } });
  return proxy;
}
const find = (node, id) => {
  if (!node || typeof node !== "object") return null;
  if (node.key === id) return node;
  for (const c of node.items) { const hit = find(c, id); if (hit) return hit; }
  return null;
};
const texts = (node) => typeof node === "string" ? [node] : node && typeof node === "object" ? node.items.flatMap(texts) : [];

function fixture(props = {}, shared = {}) {
  const f = { now: 1000, shared, rows: [], terms: [], panes: [], jobs: [], hc: [], notes: [], overlays: [], calls: [], timers: [], data: new Map(), win: { visible: true, active: true } };
  const cx = { notify() {}, stop_propagation() {}, focus_handle: () => ({ focus() {} }), spawn: (fn) => f.jobs.push(fn),
    timer: { every: () => ({}), after: (ms, fn) => { f.timers.push([ms, fn]); return { cancel() {} }; } } };
  const RealDate = Date;
  const FakeDate = class extends RealDate { constructor(...a) { super(...(a.length ? a : [f.now])); } static now() { return f.now; } };
  const env = {
    View: class {}, div: element, image: element, svg: element, v_flex: element, h_flex: element,
    Scrollbar: { vertical: element }, Date: FakeDate, checking: () => false,
    spaces: () => [{ id: "s1", tabs: [] }],
    localStorage: { getItem: (k) => f.data.get(k) ?? null, setItem: (k, v) => f.data.set(k, v) },
    agents: () => f.rows, terminals: () => f.terms, panes: () => f.panes, window: () => f.win,
    focused: () => null, theme: () => ({}), settings: () => ({}), props: () => props, layout: () => ({}),
    shared: (k) => f.shared[k] ?? null, setShared: (k, v) => { f.shared[k] = v; }, setAgentOrder() {}, run: (...a) => f.calls.push(a), notify: (n) => f.notes.push(n),
    openOverlay: (o) => f.overlays.push(o), closeOverlay() {},
    beadsDir: async () => "/beads", loadSummaries: async (orchs, dir) => { f.asked = [orchs, dir]; if (f.failRead) throw new Error("locked"); return f.sessions ?? new Map(); },
    statusMs: async (a) => f.liveMs?.[a] ?? null, home: () => "/h", appHome: () => "/a",
    exec: async () => ({ code: 1 }), readTextFile: async () => null, writeTextFile: async () => {},
    nextCommand: () => new Promise(() => {}),
    hc: async (args) => {
      f.hc.push(args);
      if (args[0] === "get" && f.get?.[args[1]]) return { code: 0, stdout: JSON.stringify(f.get[args[1]]) };
      if (args[0] === "keys" && f.afterKeys) f.screen = f.afterKeys;
      return args[0] === "read" ? { code: 0, stdout: f.screen ?? "" } : { code: 0, stdout: "" };
    },
  };
  const strip = (s) => s.replace(/^import .*;\r?\n/gm, "").replace(/export (function|const|class) /g, "$1 ");
  const src = ["tree", "terminal", "events", "words", "tasks", "name", "clock"].map((m) => strip(fs.readFileSync(path.join(dir, `${m}.js`), "utf8"))).join("")
    + strip(fs.readFileSync(path.join(dir, "main.js"), "utf8")).replace("export default class", "globalThis.Mod = class");
  f.env = env;
  vm.runInContext(src, vm.createContext(env));
  f.mod = new env.Mod(); f.mod.init({}, cx);
  f.jobs.length = 0; // the start-up passes (installs, sessions) aren't under test
  f.add = (address, status = "idle", app = "claude-code") => {
    const row = { address, status, app, space: "s1", pane: `p-${address}`, program: {}, focused: false };
    f.rows.push(row);
    f.terms.push({ address, state: "live", status, status_ms: 100, turn: 0, labels: {} });
    return row;
  };
  f.render = (now = f.now) => { f.now = now; return (f.tree = f.mod.render(cx)); };
  f.drain = async () => { while (f.jobs.length) await f.jobs.shift()(cx); };
  // The core answers labels as `hc label` would.
  f.land = async () => { await f.drain(); for (const [cmd, addr, ...kv] of f.hc) if (cmd === "label") for (const s of kv) { const [k, v] = s.split("="); f.terms.find((t) => t.address === addr).labels[k] = v; } };
  f.cx = cx;
  return f;
}

test("settling again retires again; 'closing' only while it runs", async () => {
  const f = fixture(), a = f.add("A"); a.focused = true;
  f.render(); f.mod.open = true;
  f.mod.settleKey(f.cx); f.render(); // the label is pending; retire() is under way
  assert.ok(texts(find(f.tree, "slim-A")).includes("closing"));
  await f.land(); f.render(); // no resume line appeared: left open
  assert.equal(f.notes.at(-1).title, "Settled, still running");
  assert.ok(!texts(find(f.tree, "slim-A")).includes("closing"), "a failed exit doesn't read closing forever");
  // New work brings it back (unsettled), then it's settled once more.
  f.terms[0].turn = 1; f.render(); await f.land(); f.render();
  assert.equal(f.terms[0].labels.settled, "");
  const keys = () => f.hc.filter((x) => x[0] === "keys").length, before = keys();
  f.mod.settleKey(f.cx);
  assert.ok(f.mod.closing.has("A"), "the second settle exits it again");
  await f.land();
  assert.equal(keys(), before + 2);
});

test("a snoozed agent waits on the Snoozed shelf until its time", async () => {
  const f = fixture(); f.add("A"); f.add("B");
  f.terms[0].labels.snoozed = "5000:900"; f.mod.napOpen = true;
  f.render();
  assert.ok(find(f.tree, "nap-A") && !find(f.tree, "card-A"));
  assert.ok(find(f.tree, "card-B"));
  f.render(5000); await f.land(); f.render();
  assert.equal(f.terms[0].labels.snoozed, "");
  assert.ok(find(f.tree, "card-A") && !find(f.tree, "nap-A"));
});

test("needing the person wakes it early", async () => {
  const f = fixture(), a = f.add("A", "working"); f.terms[0].labels.snoozed = "99999:900";
  f.render(); assert.ok(!find(f.tree, "card-A"));
  a.status = "blocked"; f.render(); await f.land(); f.render();
  assert.ok(find(f.tree, "card-A"));
});

test("the menu snoozes the agent it was opened for", async () => {
  // The menu is its own copy and ends as it closes: the sidebar copy writes the label.
  const shared = {}, menu = fixture({ snooze: "A", overlay: 7 }, shared), f = fixture({}, shared); menu.add("A"); f.add("A");
  menu.render(1000);
  find(menu.tree, "snooze-1h").handlers.on_click({}, menu.cx);
  assert.deepEqual(menu.hc, [], "the closing menu sends nothing itself");
  f.render(1000);
  assert.ok(find(f.tree, "nap-A") || !find(f.tree, "card-A"), "hidden at once");
  await f.drain();
  assert.deepEqual(Array.from(f.hc.at(-1)), ["label", "A", "snoozed=3601000:1000"]);
  assert.equal(shared["panda-focus.snooze"], null);
});

test("pins are the core's, in this window's order; old shared pins move onto their terminals once", () => {
  const f = fixture({}, { "agents.pins": ["C", "A", "gone"] }); f.add("A"); f.add("B").pinned = true; f.add("C").pinned = true;
  f.render();
  const ids = (n) => !n || typeof n !== "object" ? [] : [...(/^card-/.test(n.key ?? "") ? [n.key] : []), ...n.items.flatMap(ids)];
  assert.deepEqual(ids(find(f.tree, "focus-list")), ["card-C", "card-B", "card-A"], "A isn't core-pinned yet; B was pinned elsewhere (the phone): it goes last");
  f.terms[2].labels["herdr.pinned"] = "true";
  f.mod.movePins(); f.mod.movePins();
  assert.deepEqual(JSON.parse(JSON.stringify(f.calls.filter((c) => c[0] === "terminal.pin"))), [["terminal.pin", { terminal: "A", pinned: true }]],
    "only A moves: C is pinned already, `gone` isn't live, and the move runs once");
});

test("a resume line that doesn't bring its agent back is kept as a closed row", async () => {
  const f = fixture(), line = "claude --resume 049f0907-574a-46f6-9784-68a7ceea3505";
  const k = { address: "A", pid: 2, cwd: "/w", labels: { resume: line, "resume.pid": "1", where: "x / ci", "herdr.space": "s1" } };
  // Claude refused and exited: the shell is back at its prompt, no agent status.
  f.get = { A: { address: "A", state: "live", foreground: { name: "zsh" }, status: null } };
  await f.mod.restore(k);
  assert.deepEqual(Array.from(f.hc.find((x) => x[0] === "send")), ["send", "A", line]);
  await f.mod.confirmResume(k, line);
  assert.equal(f.shared["panda-focus.closed"][0].argv.join(" "), line);
  assert.equal(f.notes.at(-1).title, "Couldn't resume the agent");
  // Came up (or still starting behind a dialog): nothing kept.
  for (const now of [{ foreground: { name: ".claude-wrapped" }, status: { app: "claude-code" } }, { foreground: { name: ".claude-wrapped" }, status: null }]) {
    const g = fixture(); g.get = { A: { address: "A", state: "live", ...now } };
    await g.mod.confirmResume(k, line);
    assert.equal(g.shared["panda-focus.closed"], undefined);
  }
});

const LINE = "claude --resume 049f0907-574a-46f6-9784-68a7ceea3505";

test("the resume line carries the worker's identity from its env prefix", () => {
  const { envPrefix, resumeWithEnv } = fixture().env;
  const argv = ["env", "BEADS_ACTOR=w-abc-12-keys", "AGENT_BROWSER_NAMESPACE=ns1", "ORCH_BEAD=bd-1", "BEADS_DIR=/data/beads",
    "BEADS_DOLT_SHARED_SERVER=1", "OTHER=x", "claude", "--flag", "ORCH_BEAD=late"];
  assert.equal(envPrefix(argv), "AGENT_BROWSER_NAMESPACE=ns1 BEADS_ACTOR=w-abc-12-keys ORCH_BEAD=bd-1 BEADS_DIR=/data/beads BEADS_DOLT_SHARED_SERVER=1",
    "kept keys only, in a fixed order, and nothing after the command");
  assert.equal(envPrefix(["env", "BEADS_DIR=/with space/db", "BEADS_ACTOR=", "ORCH_BEAD=ok", "pi"]), "ORCH_BEAD=ok", "no value with whitespace or empty");
  assert.equal(envPrefix(["/usr/bin/env", "-i", "BEADS_ACTOR=w-1", "pi"]), "BEADS_ACTOR=w-1");
  assert.equal(envPrefix(["claude"]), "");
  assert.equal(envPrefix(undefined), "");
  assert.equal(resumeWithEnv(["env", "ORCH_BEAD=bd-1", "pi"], "pi --session s1"), "env ORCH_BEAD=bd-1 pi --session s1");
  assert.equal(resumeWithEnv(["pi"], "pi --session s1"), "pi --session s1");
});

test("hibernating a worker labels its resume line with its identity", async () => {
  const f = fixture(), live = { address: "W", state: "live", name: "w-abc-12-keys", parent: "O", cwd: "/w", labels: { hibernate: "ok" },
    status: { app: "claude-code", state: "idle" }, status_ms: 1, foreground: { name: "claude" }, argv: ["env", "BEADS_ACTOR=w-abc-12-keys", "ORCH_BEAD=bd-1", "claude"] };
  f.get = { W: live }; f.screen = ""; f.afterKeys = LINE;
  await f.mod.hibernate(live, { address: "W", program: { name: "Claude Code" } });
  const set = f.hc.find((x) => x[0] === "label" && String(x[2]).startsWith("resume="));
  assert.equal(set[2], `resume=env BEADS_ACTOR=w-abc-12-keys ORCH_BEAD=bd-1 ${LINE}`);
  assert.equal(f.shared["panda-focus.hibernated"][0].line, `env BEADS_ACTOR=w-abc-12-keys ORCH_BEAD=bd-1 ${LINE}`);
});

// An orchestrator O with two tasks: ABC-12 waits on the person, ABC-13 is merged.
const session = () => ({
  epic: { id: "e1" },
  beads: [
    { id: "b1", title: "Keys", status: "in_progress", assignee: "w-abc-12-keys", external_ref: "https://example.test/browse/ABC-12", metadata: { blocked_reason: "needs-user" } },
    { id: "b2", title: "Docs", status: "closed", external_ref: "https://example.test/browse/ABC-13", metadata: { merged_sha: "abc" } },
  ],
  deps: {}, reviews: {}, comments: {},
});
// Working agents sit on the Working shelf, folded by default: open it so their cards draw.
const orchestrator = (f) => { f.mod.workOpen = true; const a = f.add("O", "working"); f.terms[0].labels["orch-context"] = "/s/status.sh"; return a; };

test("orchestrator summaries are read while the window shows, published when they change, and say so on the card", async () => {
  const f = fixture(); orchestrator(f); f.sessions = new Map([["O", { session: session(), extra: 0 }]]);
  f.render();
  f.win = { visible: false };
  f.mod.summarize(f.cx); await f.drain();
  assert.equal(f.asked, undefined, "nothing is read while the window is hidden");
  f.win = { visible: true };
  f.mod.summarize(f.cx); await f.drain();
  assert.deepEqual(JSON.parse(JSON.stringify(f.asked)), [["O"], "/beads"]);
  const got = f.shared["orch.summary"].O;
  assert.equal(got.text, "your turn on ABC-12 · 1/2 done");
  assert.deepEqual([got.epic, got.total, got.merged, got.you, got.youBead, got.youKey], ["e1", 2, 1, 1, "b1", "ABC-12"]);
  f.render();
  assert.ok(texts(find(f.tree, "card-O")).includes("your turn on ABC-12 · 1/2 done"), "the workers chip says it");
  // The same answer again writes nothing; a changed one does.
  got.at = 7; f.mod.summarize(f.cx); await f.drain();
  assert.equal(f.shared["orch.summary"].O.at, 7);
  f.sessions = new Map([["O", { session: { ...session(), beads: session().beads.slice(1) }, extra: 0 }]]);
  f.mod.summarize(f.cx); await f.drain();
  assert.equal(f.shared["orch.summary"].O.text, "all done", "its one task is closed");
  // A failed read drops the summaries: an old "your turn" never lingers on the card or for next-needs.
  f.failRead = true; f.mod.summarize(f.cx); await f.drain();
  assert.deepEqual(JSON.parse(JSON.stringify(f.shared["orch.summary"])), {});
  // An orchestrator whose read failed is missing from the Map: no summary for it.
  f.failRead = false; f.sessions = new Map(); f.mod.summarize(f.cx); await f.drain();
  assert.equal(f.shared["orch.summary"].O, undefined);
});

test("summaries count closed, idle and hibernated tasks as the panel does", async () => {
  const f = fixture(); orchestrator(f);
  const s = {
    epic: { id: "e1" },
    beads: [
      // Closed with no settle event: settled ("closed"), not queued.
      { id: "b1", title: "One", status: "closed", assignee: "w-one", metadata: {} },
      // Its worker idle after a report: the orchestrator's turn, not "working".
      { id: "b2", title: "Two", status: "in_progress", assignee: "w-two", metadata: { pr_url: "https://example.test/o/r/pull/2" } },
      // Hibernated worker after its report: the orchestrator's turn too.
      { id: "b3", title: "Three", status: "in_progress", assignee: "w-three", metadata: { review_round: "1" } },
    ],
    deps: {}, reviews: {},
    comments: {
      b1: [{ text: "event=dispatched agent=w-one terminal=W1", created_at: "2026-01-01T00:00:00Z", author: "o-O" }],
      b2: [{ text: "event=dispatched agent=w-two terminal=W2", created_at: "2026-01-01T00:00:00Z", author: "o-O" },
        { text: "event=report kind=pr-opened pr=https://example.test/o/r/pull/2", created_at: "2026-01-01T00:10:00Z", author: "w-two" }],
      b3: [{ text: "event=dispatched agent=w-three terminal=W3", created_at: "2026-01-01T00:00:00Z", author: "o-O" },
        { text: "event=report kind=ready-local", created_at: "2026-01-01T00:20:00Z", author: "w-three" }],
    },
  };
  f.terms.push({ address: "W2", name: "w-two", parent: "O", state: "live", status: "idle", labels: { orch: "O" } });
  f.shared["panda-focus.hibernated"] = [{ address: "W3", name: "w-three", parent: "O" }];
  f.sessions = new Map([["O", { session: s, extra: 0 }]]);
  f.render(); f.mod.summarize(f.cx); await f.drain();
  const got = f.shared["orch.summary"].O;
  assert.deepEqual([got.total, got.working, got.you, got.inPr, got.done, got.text], [3, 0, 0, 1, 1, "1/3 done"]);
});

test("a Codex worker never hibernates, even labelled hibernate=ok", () => {
  const f = fixture();
  const k = (app) => ({ address: "W", parent: "O", labels: { hibernate: "ok" }, status: { app, state: "idle" }, status_ms: 1 });
  f.now = 10 * 60000;
  assert.equal(f.mod.sleepy(k("pi")), true);
  assert.equal(f.mod.sleepy(k("claude-code")), true);
  assert.equal(f.mod.sleepy(k("codex")), false);
});

test("card times count from the core's live status time, not terminals()' stale status_ms", async () => {
  const f = fixture(); f.add("A"); f.liveMs = { A: 900 };
  f.render();
  assert.equal(f.shared["panda-focus.since"].A, 100, "the stale value only until the core answers");
  await f.drain(); f.render();
  assert.equal(f.shared["panda-focus.since"].A, 900, "then the live one, published for the Agents panel");
});

test("a parent waiting on a hidden working worker counts from the worker's live time, not its stale status_ms", async () => {
  const f = fixture(); f.mod.workOpen = true; f.add("P", "idle");
  f.terms.push({ address: "K", name: "w-k", parent: "P", state: "live", status: "working", status_ms: 50, labels: {} });
  f.liveMs = { P: 700, K: 650 };
  f.render(); await f.drain(); f.render();
  assert.equal(f.shared["panda-focus.since"].P, 650);
});

test("a summary belongs to a live orchestrator only; without one the card keeps its old words", () => {
  const f = fixture(); f.mod.workOpen = true; f.add("P", "working"); f.add("K", "working"); f.terms[1].parent = "P";
  f.shared["orch.summary"] = { P: { text: "all done", you: 0 } };
  f.render();
  assert.ok(!texts(find(f.tree, "card-P")).includes("all done"), "P is no orchestrator");
  assert.ok(texts(find(f.tree, "card-P")).includes("1 worker working"));
  f.terms[0].labels["orch-context"] = "/s/status.sh"; f.render();
  assert.ok(texts(find(f.tree, "card-P")).includes("all done"));
  const { orchestrators } = f.env;
  const live = (address, labels = {}) => ({ address, state: "live", labels });
  assert.deepEqual([...orchestrators([live("A"), live("B", { orch: "A", "orch-context": "/s/worker-context.sh" }), live("x/C", { "orch-context": "s" }),
    live("D"), live("E"), live("F"), live("G")],
  [{ terminal: "D", name: "[o] D" }, { terminal: "E", name: "other" }, { terminal: "F", name: null, title: "[O] title" }, { terminal: "G", name: null, tab: "tb" }],
  (id) => (id === "tb" ? "[o] tab" : null))].sort(), ["A", "D", "F", "G"], "the mark on a pane, title or tab, any case, as the panel reads it");
  // A dead orchestrator a child still names is not polled.
  assert.deepEqual([...orchestrators([live("K", { orch: "gone" })], [], () => null)], []);
});

test("the ticker names a child's flip or a fresh orch.in label for 3s, then drops", () => {
  const f = fixture(); f.mod.workOpen = true; f.add("O", "working"); f.add("W", "idle"); f.terms[1].parent = "O";
  f.render();
  assert.ok(!find(f.tree, "tick-O"), "first sight is no news");
  f.rows[1].status = "working"; f.terms[1].status = "working"; f.render(2000);
  assert.deepEqual(texts(find(f.tree, "tick-O")), ["↓ W working"]);
  assert.deepEqual(f.timers.map((x) => x[0]).filter((ms) => ms === 3000), [3000], "one timer per tick");
  f.render(4500); assert.ok(find(f.tree, "tick-O"), "still there while it fades");
  f.render(7000); assert.ok(!find(f.tree, "tick-O"), "dropped after the fade");
  f.rows[1].status = "idle"; f.terms[1].status = "idle"; f.render(8000);
  assert.deepEqual(texts(find(f.tree, "tick-O")), ["↑ W reported"]);
  f.terms[1].labels["orch.in"] = `${f.now - 1000}:dispatched`; f.render(8500);
  assert.deepEqual(texts(find(f.tree, "tick-O")), ["↓ dispatched W"]);
  const n = f.timers.length; f.render(8600);
  assert.equal(f.timers.length, n, "a label is news once");
  f.terms[1].labels["orch.in"] = `${f.now - 9000}:command`; f.render(9000);
  assert.deepEqual(texts(find(f.tree, "tick-O")), ["↓ dispatched W"], "a stale label is no news");
});

test("next-needs goes to the next stuck agent or waiting task, wrapping; snooze and wake follow the agent in view", async () => {
  const f = fixture(), [a] = [f.add("A", "idle"), f.add("B", "blocked"), f.add("C", "blocked")];
  a.focused = true; f.render();
  const focus = () => f.calls.splice(0).map((c) => JSON.parse(JSON.stringify(c)));
  f.mod.needsKey(f.cx);
  assert.deepEqual(focus(), [["agent.focus", { terminal: "B" }]]);
  a.focused = false; f.rows[2].focused = true; f.render(); f.mod.needsKey(f.cx);
  assert.deepEqual(focus(), [["agent.focus", { terminal: "B" }]], "wraps past the end");
  // An orchestrator with a task waiting on the person opens it in the Agents panel.
  f.rows[2].focused = false; f.rows[0].focused = true;
  f.rows.length = 1; f.terms.length = 1; f.terms[0].labels["orch-context"] = "/s/status.sh"; f.add("O", "working"); f.terms[1].labels["orch-context"] = "/s/status.sh";
  f.shared["orch.summary"] = { O: { you: 1, youBead: "b1", youKey: "ABC-12" } };
  f.render(); f.mod.needsKey(f.cx);
  assert.deepEqual(focus(), [["agent.focus", { terminal: "O" }], ["layout.select", { stack: "panel-body", child: "fleet" }], ["layout.show", { id: "panel" }]]);
  assert.deepEqual([f.shared["fleet.open"].orch, f.shared["fleet.open"].bead, f.shared["fleet.open"].at], ["O", "b1", f.now]);
  // Nothing needs the person.
  f.shared["orch.summary"] = {}; f.rows[1].focused = true; f.rows[0].focused = false; f.render(); f.mod.needsKey(f.cx);
  assert.equal(f.notes.at(-1).title, "Nothing needs you");
  // Snooze opens the menu for the one in view, but not while it needs the person.
  f.mod.snoozeKey(f.cx);
  assert.equal(f.overlays.at(-1).props.snooze, "O");
  assert.equal(f.overlays.at(-1).mod, "panda-focus");
  f.rows[1].status = "blocked"; f.terms[1].status = "blocked"; f.render(); const n = f.overlays.length; f.mod.snoozeKey(f.cx);
  assert.equal(f.overlays.length, n);
  assert.equal(f.notes.at(-1).title, "Can't snooze");
});

test("wake brings the snoozed agent in view back", async () => {
  const f = fixture(), a = f.add("A"); a.focused = true; f.terms[0].labels.snoozed = "99999:900"; f.mod.napOpen = true;
  f.render(); f.mod.wakeKey(f.cx); await f.land();
  assert.deepEqual(Array.from(f.hc.find((x) => x[0] === "label" && x[2].startsWith("snoozed="))), ["label", "A", "snoozed="]);
  assert.deepEqual(JSON.parse(JSON.stringify(f.calls[0])), ["agent.focus", { terminal: "A" }]);
});

test("the snooze menu closes through an imported closeOverlay", () => {
  const src = fs.readFileSync(path.join(dir, "main.js"), "utf8");
  assert.match(src, /^import \{[^}]*\bcloseOverlay\b[^}]*\} from "herdr";/m);
});
