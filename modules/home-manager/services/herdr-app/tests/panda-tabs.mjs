// panda-tabs: the side panel remembered per space, as the focus moves between spaces (syncPanel), and a tab nobody named
// called after its agent as the rail calls it (name.js) with the rail's status words (words.js). Stand-ins for gpui
// and herdr; made-up data.
// Run: node --experimental-vm-modules modules/home-manager/services/herdr-app/tests/panda-tabs.mjs
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

function element() {
  const node = { key: null, items: [], tip: null };
  const proxy = new Proxy(node, {
    get(target, key) {
      if (key in target) return target[key];
      return (...args) => {
        if (key === "when") { if (args[0]) args[1](proxy); } else if (key === "child") node.items.push(args[0]);
        else if (key === "children") node.items.push(...args[0]);
        else if (key === "id") node.key = args[0];
        else if (key === "tooltip") node.tip = args[0];
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
const texts = (node) => (typeof node === "string" ? [node] : node && typeof node === "object" ? (node.items ?? []).flatMap(texts) : []);

const w = { spaces: [], panes: [], agents: [], runs: [], store: new Map(), panel: { hidden: true, active: null } };
const herdr = {
  spaces: () => w.spaces, panes: () => w.panes, agents: () => w.agents, theme: () => ({}), window: () => ({ platform: "linux" }),
  // herdr-panda offers these panels (shared "workspace.panels").
  shared: (k) => (k === "workspace.panels" ? ["fleet", "files", "changes"] : null), settings: () => ({ zoom: 1 }), checking: () => false, nextCommand: () => new Promise(() => {}),
  openOverlay() {},
  layout: () => ({ id: "root", children: [{ id: "panel", hidden: w.panel.hidden, children: [] }, { id: "panel-body", active: w.panel.active, children: [] }] }),
  // layout.select / show / hide act on the stand-in panel, as the app would.
  run: (name, args) => {
    w.runs.push([name, args]);
    if (name === "layout.select") w.panel.active = args.child;
    if (name === "layout.show") w.panel.hidden = false;
    if (name === "layout.hide") w.panel.hidden = true;
    return null;
  },
};
const context = vm.createContext({
  console, Date, JSON, Math, Map, Set, Object, Array, String, Number, Promise, RegExp,
  localStorage: { getItem: (k) => w.store.get(k) ?? null, setItem: (k, v) => w.store.set(k, v) },
});
const synth = (exports) => new vm.SyntheticModule(Object.keys(exports), function () { for (const [k, v] of Object.entries(exports)) this.setExport(k, v); }, { context });
const natives = { herdr: synth(herdr), "gpui-kit": synth({ View: class {}, div: element, svg: element, image: element }), "gpui-base": synth({ h_flex: element }) };
const cache = new Map();
async function load(url) {
  if (!cache.has(url.href)) cache.set(url.href, new vm.SourceTextModule(await readFile(url, "utf8"), { context, identifier: url.href }));
  return cache.get(url.href);
}
const main = await load(new URL("../mods/panda-tabs/main.js", import.meta.url));
await main.link((name, parent) => natives[name] ?? load(new URL(name, parent.identifier)));
await main.evaluate();
const Tabs = main.namespace.default;

const tabs = new Tabs();
tabs.init({}, { spawn() {} });
const space = (id, active, tabList = [{ id: `${id}-t`, name: "1", named: false, active: true, status: null }]) => ({ id, name: id, active, tabs: tabList });
const show = (a) => { w.spaces = [space("A", a === "A"), space("B", a === "B")]; return tabs.render(); };
// A space switch: the render that restores the space's panel, then the one that sees the restore land.
const go = (a) => { show(a); return show(a); };

// Space A: the person opens the Agents panel; it is recorded for A.
show("A");
herdr.run("layout.select", { stack: "panel-body", child: "fleet" }); herdr.run("layout.show", { id: "panel" });
show("A");
assert.equal(JSON.parse(w.store.get("panels")).A, "fleet");
// To B, which never had a panel choice of its own: the panel closes there.
w.runs.length = 0;
go("B");
assert.equal(w.panel.hidden, true);
// Back to A: its Agents panel comes back.
go("A");
assert.deepEqual([w.panel.hidden, w.panel.active], [false, "fleet"]);
// Closing it in A is A's choice; B opening Files is B's.
herdr.run("layout.hide", { id: "panel" }); show("A");
assert.equal(JSON.parse(w.store.get("panels")).A, null);
go("B"); herdr.run("layout.select", { stack: "panel-body", child: "files" }); herdr.run("layout.show", { id: "panel" }); show("B");
go("A");
assert.equal(w.panel.hidden, true, "A stays closed");
go("B");
assert.deepEqual([w.panel.hidden, w.panel.active], [false, "files"], "B gets Files back");
// A restore not yet landed isn't taken for the person's choice (the pending window).
const stored = w.store.get("panels");
w.run = herdr.run; herdr.run = (name, args) => { w.runs.push([name, args]); return null; }; // the app hasn't acted yet
show("A"); show("A");
assert.equal(w.store.get("panels"), stored, "nothing recorded while the restore is pending");
herdr.run = w.run;

// A tab nobody named is called after its agent, as name.js calls it; its status word is the rail's.
// An unnamed tab's name is its position ("1", named: false), as herdr.d.ts TabInfo gives it.
w.spaces = [space("A", true, [{ id: "t1", name: "1", named: false, active: true, status: "blocked" }, { id: "t2", name: "Mine", named: true, active: false, status: "working" },
  { id: "t3", name: "3", named: false, active: false, status: null }])];
w.panes = [{ pane: "p1", terminal: "a1", tab: "t1", name: "fix the keys", program: { agent: true, name: "Claude Code" } }];
w.agents = [{ address: "a1", tab: "t1", status: "blocked", pane_name: "fix the keys", program: { name: "Claude Code" } }];
const tree = tabs.render();
assert.ok(texts(find(tree, "tab-t1")).includes("fix the keys"), "the agent's name, not the program's");
assert.ok(texts(find(tree, "tab-t2")).includes("Mine"), "a tab someone named keeps its name");
assert.ok(texts(find(tree, "tab-t3")).includes("3"), "an unnamed tab with no agent keeps its number");
assert.equal(find(tree, "status-t1").tip, "Needs you");
assert.equal(find(tree, "status-t2").tip, "Working");

console.log("panda-tabs: ok");
