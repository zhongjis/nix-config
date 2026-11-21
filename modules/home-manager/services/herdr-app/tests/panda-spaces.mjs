// panda-spaces checks: a click's terminal and folder (mods/shared/terminal.js), and the worktree list read from the
// git common dir, so a removed worktree's folder can't freeze it.
// Run: nix shell nixpkgs#nodejs --command node --experimental-vm-modules modules/home-manager/services/herdr-app/tests/panda-spaces.mjs
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import vm from "node:vm";

let execs = [], onExec = () => ({ code: 0, stdout: "", stderr: "" });
const context = vm.createContext({ console, Date, JSON });
const herdr = new vm.SyntheticModule(["exec", "shared", "setShared"], function () {
  this.setExport("exec", async (cmd, args, opts) => { execs.push([cmd, args, opts]); return onExec(cmd, args, opts); });
  this.setExport("shared", () => null);
  this.setExport("setShared", () => {});
}, { context });
const cache = new Map();
async function load(url) {
  if (!cache.has(url.href)) cache.set(url.href, new vm.SourceTextModule(await readFile(url, "utf8"), { context, identifier: url.href }));
  return cache.get(url.href);
}
async function module(path) {
  const m = await load(new URL(path, import.meta.url));
  await m.link((name, parent) => name === "herdr" ? herdr : load(new URL(name, parent.identifier)));
  await m.evaluate();
  return m.namespace;
}
const { firstTerminal, firstFolder } = await module("../mods/panda-spaces/terminal.js");
const { Repositories } = await module("../mods/panda-spaces/repos.js");
// main.js against stand-ins: each native module exports whatever main.js imports from it.
let liveSpaces = [], livePanes = [], runs = [];
const stand = { spaces: () => liveSpaces, panes: () => livePanes, run: (name, args) => runs.push([name, args]), home: () => "/home/me" };
const mainSrc = await readFile(new URL("../mods/panda-spaces/main.js", import.meta.url), "utf8");
const natives = {};
for (const [, names, from] of mainSrc.matchAll(/^import \{([^}]+)\} from "([^.][^"]*)";/gm)) {
  const list = names.split(",").map((n) => n.trim()).filter(Boolean);
  natives[from] = new vm.SyntheticModule(list, function () {
    for (const n of list) this.setExport(n, n in stand ? stand[n] : from === "herdr" && n === "exec" ? (...a) => (execs.push(a), onExec(...a)) : class {});
  }, { context });
}
const main = await load(new URL("../mods/panda-spaces/main.js", import.meta.url));
await main.link((name, parent) => natives[name] ?? (name === "herdr" ? herdr : load(new URL(name, parent.identifier))));
await main.evaluate();
const Spaces = main.namespace.default;

// The shown tab first; agents (a status, or an agent program) are skipped; a busy shell counts.
const space = { tabs: [{ id: "a", active: false }, { id: "b", active: true }] };
const pane = (pane, tab, extra = {}) => ({ pane, tab, terminal: `t-${pane}`, status: null, program: { agent: false }, ...extra });
assert.equal(firstTerminal(space, [pane("p1", "a"), pane("p2", "b", { status: "idle" }), pane("p3", "b", { program: { agent: false, shell: false } })]).pane, "p3");
assert.equal(firstTerminal(space, [pane("p1", "a"), pane("p2", "b", { program: { agent: true } })]).pane, "p1");
assert.equal(firstTerminal(space, [pane("p1", "a", { status: "working" }), pane("p2", "b", { terminal: null, mod: "files" })]), null);

// The first folder that exists there; null when none does or the machine can't be asked.
onExec = (_cmd, args) => ({ code: args[1] === "/main" ? 0 : 1 });
execs = [];
assert.equal(await firstFolder(["/gone", null, "/main", "/space"], "vps"), "/main");
assert.deepEqual(execs.map(([c, a, o]) => [c, a[1], o.on]), [["test", "/gone", "vps"], ["test", "/main", "vps"]]);
onExec = () => { throw new Error("unreachable"); };
assert.equal(await firstFolder(["/a"], null), null);

// The list is asked in the common dir, never in the space's (removed) folder.
const repos = new Repositories();
const jobs = [];
execs = [];
onExec = (_cmd, args) => args.includes("worktree") ? { code: 0, stdout: "worktree /r\nHEAD 1\nbranch refs/heads/main\n" } : { code: 1, stdout: "" };
repos.refresh({ repo: JSON.stringify(["vps", "/r/.git"]), folder: "/removed-worktree" }, { spawn: (fn) => jobs.push(fn({ notify() {} })) });
await Promise.all(jobs);
assert.equal(execs[0][2].cwd, "/r/.git");
assert.equal(JSON.stringify(repos.groups[JSON.stringify(["vps", "/r/.git"])].worktrees), JSON.stringify([{ folder: "/r", branch: "main" }]));

// A click: the shown tab's terminal; without one a new shell tab in a folder that exists, once per burst.
{
  const view = Object.create(Spaces.prototype);
  Object.assign(view, { opening: {}, gone: {} });
  const spawned = [], cx = { spawn: (fn) => spawned.push(fn(cx)) };
  liveSpaces = [{ id: "s", machine: null, folder: "/made", tabs: [{ id: "a", active: true }, { id: "b", active: false }] }];
  livePanes = [pane("p1", "a", { status: "working", program: { agent: true } }), pane("p2", "b"), { pane: "p3", tab: "b", terminal: null, mod: "files" }];
  runs = [];
  view.go({ id: "s" }, cx);
  assert.equal(JSON.stringify(runs), JSON.stringify([["space.select", { id: "s" }], ["pane.focus", { pane: "p2" }]]));

  // Only an agent: a shell tab in the repo's main checkout (the live folder is a removed worktree).
  livePanes = [pane("p1", "a", { status: "idle", cwd: "/wt (deleted)" })];
  view.gone[JSON.stringify([null, "/wt"])] = { main: "/repo", worktree: true };
  onExec = (_c, args) => ({ code: args[1] === "/repo" ? 0 : 1 });
  runs = [];
  view.go({ id: "s" }, cx);
  view.go({ id: "s" }, cx);
  await Promise.all(spawned);
  assert.equal(JSON.stringify(runs), JSON.stringify([["space.select", { id: "s" }], ["space.select", { id: "s" }], ["tab.new", { space: "s", focus: true, folder: "/repo" }]]));
}

// The worktree menu: uncommitted changes are counted first; with some, removal goes with --force.
{
  const src = await readFile(new URL("../mods/panda-worktree-menu/main.js", import.meta.url), "utf8");
  const shared = [];
  const names = { props: () => ({ folder: "/wt", common: "/r/.git", machine: null, repo: "k", overlay: 1 }), setShared: (k, v) => shared.push([k, v]), closeOverlay() {}, notify() {}, run() {}, theme: () => ({}) };
  const mk = (list, from) => new vm.SyntheticModule(list, function () {
    for (const n of list) this.setExport(n, n in names ? names[n] : n === "exec" ? async (...a) => (execs.push(a), onExec(...a)) : class {});
  }, { context });
  const mods = {};
  for (const [, l, from] of src.matchAll(/^import \{([^}]+)\} from "([^"]+)";/gm)) mods[from] = mk(l.split(",").map((n) => n.trim()), from);
  const m = new vm.SourceTextModule(src, { context });
  await m.link((name) => mods[name]);
  await m.evaluate();
  const menu = Object.create(m.namespace.default.prototype);
  Object.assign(menu, { asking: false, busy: false, error: null, dirty: null });
  const jobs = [], cx = { notify() {}, spawn: (fn) => jobs.push(fn(cx)) };
  execs = [];
  onExec = (_c, args) => args[0] === "status" ? { code: 0, stdout: " M a\n?? b\n" } : { code: 0, stdout: "" };
  menu.remove(cx); // not counted yet: nothing runs
  menu.choose(2, cx);
  await Promise.all(jobs.splice(0));
  assert.equal(menu.dirty, 2);
  menu.remove(cx);
  await Promise.all(jobs.splice(0));
  assert.equal(JSON.stringify(execs.map(([, a]) => a)), JSON.stringify([["status", "--porcelain"], ["worktree", "remove", "--force", "/wt"]]));
  assert.equal(shared[0][0], "panda-spaces.stale");
}

// Real git: from the common dir, a removed worktree is gone from the list.
const dir = mkdtempSync(join(tmpdir(), "panda-spaces-"));
try {
  const git = (...a) => execFileSync("git", a, { cwd: join(dir, "repo"), encoding: "utf8" });
  execFileSync("git", ["init", "-q", "repo"], { cwd: dir });
  git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "i");
  git("worktree", "add", "-q", "../wt", "-b", "feat");
  git("worktree", "remove", "../wt");
  assert.ok(!existsSync(join(dir, "wt")));
  const list = execFileSync("git", ["worktree", "list", "--porcelain"], { cwd: join(dir, "repo/.git"), encoding: "utf8" });
  assert.ok(list.includes(`worktree ${join(dir, "repo")}`) && !list.includes("/wt"));
} finally { rmSync(dir, { recursive: true, force: true }); }

console.log("panda-spaces: ok");
