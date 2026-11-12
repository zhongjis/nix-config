// panda-focus checks: settled agents retire on every settle, "closing" shows only while exiting, and snooze.
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
  const f = { now: 1000, shared, rows: [], terms: [], jobs: [], hc: [], notes: [], overlays: [], calls: [], data: new Map() };
  const cx = { notify() {}, stop_propagation() {}, focus_handle: () => ({ focus() {} }), spawn: (fn) => f.jobs.push(fn),
    timer: { every: () => ({}), after: () => ({ cancel() {} }) } };
  const RealDate = Date;
  const FakeDate = class extends RealDate { constructor(...a) { super(...(a.length ? a : [f.now])); } static now() { return f.now; } };
  const env = {
    View: class {}, div: element, image: element, svg: element, v_flex: element, h_flex: element,
    Scrollbar: { vertical: element }, namer: () => (a) => a.address, Date: FakeDate,
    localStorage: { getItem: (k) => f.data.get(k) ?? null, setItem: (k, v) => f.data.set(k, v) },
    agents: () => f.rows, terminals: () => f.terms, panes: () => [], spaces: () => [{ id: "s1", tabs: [] }],
    focused: () => null, theme: () => ({}), settings: () => ({}), props: () => props, layout: () => ({}), window: () => null,
    shared: (k) => f.shared[k] ?? null, setShared: (k, v) => { f.shared[k] = v; }, setAgentOrder() {}, run: (...a) => f.calls.push(a), notify: (n) => f.notes.push(n),
    openOverlay: (o) => f.overlays.push(o), closeOverlay() {}, home: () => "/h", appHome: () => "/a",
    exec: async () => ({ code: 1 }), readTextFile: async () => null, writeTextFile: async () => {},
    nextCommand: () => new Promise(() => {}),
    hc: async (args) => { f.hc.push(args); return args[0] === "read" ? { code: 0, stdout: f.screen ?? "" } : { code: 0, stdout: "" }; },
  };
  const strip = (s) => s.replace(/^import .*;\r?\n/gm, "").replace(/export (function|const) /g, "$1 ");
  const src = strip(fs.readFileSync(path.join(dir, "tree.js"), "utf8"))
    + strip(fs.readFileSync(path.join(dir, "main.js"), "utf8")).replace("export default class", "globalThis.Mod = class");
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
  const f = fixture({ snooze: "A", overlay: 7 }); f.add("A");
  f.render(1000);
  find(f.tree, "snooze-1h").handlers.on_click({}, f.cx);
  await new Promise((r) => setImmediate(r));
  assert.deepEqual(Array.from(f.hc.at(-1)), ["label", "A", "snoozed=3601000:1000"]);
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
