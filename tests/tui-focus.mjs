// Run: nix shell nixpkgs#nodejs --command node --experimental-vm-modules tests/tui-focus.mjs
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

let now = 1000000, liveAgents = [], liveTerminals = [], livePanes = [], liveSpaces = [];
let events = [], failCreation = false, onKeys = () => {}, reads = 0;
const saved = new Map(), tasks = [], timers = [];
const result = { code: 0, stdout: "", stderr: "" };
const api = {
  agents: () => liveAgents, terminals: () => liveTerminals,
  panes: () => livePanes, spaces: () => liveSpaces,
  shared: (key) => saved.get(key), setShared: (key, value) => saved.set(key, value),
  notify: (value) => events.push(["notify", value]),
  run: (name, args) => {
    events.push([name, args]);
    if (name === "pane.close") {
      const p = livePanes.find((p) => p.pane === args.pane);
      livePanes = livePanes.filter((q) => q !== p);
      for (const s of liveSpaces) {
        for (const t of s.tabs) if (t.id === p.tab) t.panes--;
        s.tabs = s.tabs.filter((t) => t.panes > 0);
      }
      liveSpaces = liveSpaces.filter((s) => s.tabs.length);
    }
    return null;
  },
  exec: async () => result,
  hc: async (args) => {
    if (args[0] === "run") {
      // The replacement tab comes from the core, never tab.new (which would select it).
      events.push(["hc.run", args]);
      if (failCreation === "reject") throw new Error("launch failed");
      if (failCreation === "unlisted") return result;
      if (failCreation) return { ...result, code: 1, stderr: "creation failed" };
      const label = (k) => args.find((a) => a.startsWith(`${k}=`)).slice(k.length + 1);
      assert.ok(args.includes("--no-parent") && args.includes("--bg"));
      assert.equal(args[args.indexOf("--cwd") + 1], "/live");
      liveSpaces.find((s) => s.id === label("herdr.space")).tabs.push({ id: label("herdr.tab"), panes: 1, blank: true });
      return result;
    }
    if (args[0] === "keys") onKeys();
    return { ...result, stdout: args[0] === "read" && reads++ > 0 ? "pi --session abc123" : "" };
  },
  focused: () => null, openOverlay() {}, theme: () => ({}), setAgentOrder() {},
  props: () => ({}), nextCommand: () => new Promise(() => {}), settings: () => ({}),
  layout: () => ({}), home: () => "/home/test", appHome: () => "/app", readTextFile: async () => null,
};
class Clock extends Date { static now() { return now; } }
const context = vm.createContext({ Date: Clock, console, localStorage: { getItem: () => null } });
const native = (bindings) => new vm.SyntheticModule(Object.keys(bindings), function () {
  for (const [key, value] of Object.entries(bindings)) this.setExport(key, value);
}, { context });
const natives = {
  herdr: native(api),
  "gpui-kit": native({ View: class {}, div() {}, image() {}, svg() {} }),
  "gpui-base": native({ v_flex() {}, h_flex() {} }),
};
const cache = new Map();
async function load(url) {
  if (!cache.has(url.href)) cache.set(url.href, new vm.SourceTextModule(await readFile(url, "utf8"), { context, identifier: url.href }));
  return cache.get(url.href);
}
const mod = await load(new URL("../modules/home-manager/services/herdr-app/mods/tui-focus/main.js", import.meta.url));
await mod.link((name, parent) => natives[name] ?? load(new URL(name, parent.identifier)));
await mod.evaluate();
const Focus = mod.namespace.default;
const cx = {
  notify() {}, focus_handle() {},
  spawn: (fn) => tasks.push(Promise.resolve().then(() => fn(cx))),
  timer: { every: (ms, fn) => timers.push({ ms, fn }) },
};
async function drain() { while (tasks.length) await Promise.all(tasks.splice(0)); }
function fixture(extra = {}) {
  events = []; reads = 0; saved.clear(); failCreation = false; onKeys = () => {};
  liveAgents = [{ address: "t1", pane: "p1", tab: "tab1", space: "s1", app: "pi", status: "idle", focused: false, ...extra }];
  liveTerminals = [{ address: liveAgents[0].address, cwd: "/live", labels: { settled: `${now - 45000}:0` } }];
  livePanes = [{ pane: "p1", terminal: liveAgents[0].address, tab: "tab1", cwd: "/live" }];
  liveSpaces = [{ id: "s1", folder: "/old", tabs: [{ id: "tab1", panes: 1 }] }];
  const focus = new Focus(); focus.tried = new Set(); return focus;
}
const actions = () => events.filter(([name]) => name !== "notify").map(([name]) => name);

// Drive the registered scheduler, not just the delay constant.
const focus = fixture();
focus.installPi = async () => {};
focus.sessions = () => {};
// Do not start the permanent command reader in this isolated scheduler check.
const initCx = { ...cx, spawn() {} };
focus.init({}, initCx);
const settledAt = now - 45000;
now = settledAt + 44999;
for (const timer of timers.filter((t) => 44999 % t.ms === 0)) timer.fn(cx);
focus.closeDue(cx); await drain();
assert.deepEqual(actions(), []);
now = settledAt + 45000;
for (const timer of timers.filter((t) => 45000 % t.ms === 0)) timer.fn(cx);
await drain();
assert.deepEqual(actions(), ["hc.run", "pane.close"]);
assert.equal(liveSpaces.length, 1);
assert.ok(liveSpaces[0].tabs[0].blank);
assert.equal(saved.get("tui-focus.closed")[0].argv.join(" "), "pi --session abc123");

for (const extra of [{ focused: true }, { status: "working" }, { status: "blocked" }, { address: "remote/t1" }, { app: "codex" }]) {
  fixture(extra).closeDue(cx); await drain(); assert.deepEqual(actions(), []);
}
for (const kind of ["split", "tabs", "late-close", "failure", "reject", "unlisted", "missing-resume"]) {
  const f = fixture();
  if (kind === "split") liveSpaces[0].tabs[0].panes = 2;
  if (kind === "tabs" || kind === "late-close") liveSpaces[0].tabs.push({ id: "other", panes: 1 });
  if (kind === "late-close") onKeys = () => { liveSpaces[0].tabs.pop(); };
  if (kind === "failure" || kind === "reject" || kind === "unlisted") failCreation = kind === "failure" ? true : kind;
  if (kind === "missing-resume") reads = -100;
  f.closeDue(cx); await drain();
  const expected = kind === "split" || kind === "tabs" ? ["pane.close"]
    : kind === "failure" || kind === "reject" || kind === "unlisted" ? ["hc.run"]
    : kind === "missing-resume" ? [] : ["hc.run", "pane.close"];
  assert.deepEqual(actions(), expected, kind);
  assert.equal(liveSpaces.length, 1, kind);
}
// Recovered settled shells use the same preservation boundary.
for (const failed of [false, true]) {
  const f = fixture(); failCreation = failed;
  await f.restore({ address: "t1", pid: 2, cwd: "/live", labels: {
    resume: "pi --session abc123", "resume.pid": "1", settled: "1:0", "herdr.space": "s1",
  } });
  assert.deepEqual(actions(), failed ? ["hc.run"] : ["hc.run", "pane.close"]);
}
// The separate orchestrator-worker threshold remains five minutes.
const f = fixture(), worker = { parent: "parent", address: "worker", labels: { hibernate: "ok" }, status: { state: "idle" } };
assert.equal(f.sleepy({ ...worker, status_ms: now - 299999 }), false);
assert.equal(f.sleepy({ ...worker, status_ms: now - 300000 }), true);
console.log("tui-focus regression checks passed");
