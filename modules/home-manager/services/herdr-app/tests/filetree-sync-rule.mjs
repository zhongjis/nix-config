// Relevant checks vendored/adapted from ChmaraX/herdr-nvim's
// herdr-app/e2e/js-checks.mjs (MIT; ../mods/filetree/LICENSE-herdr-nvim).
// Run: node modules/home-manager/services/herdr-app/tests/filetree-sync-rule.mjs
import assert from "node:assert/strict";
import { register } from "node:module";
import { wanted } from "../mods/filetree/sync-rule.js";

const tab = (files, nvim, other = false) => ({ tab: "a", files, other, nvim });

assert.deepEqual(wanted(tab(false, true), { ...tab(true, true), tab: "b" }), { panel: "show" });
assert.deepEqual(wanted(tab(true, false), null), { panel: null }, "a tab without nvim keeps its panel");
assert.deepEqual(wanted(tab(true, false), tab(false, false)), {}, "opening the tree starts no nvim");
assert.deepEqual(wanted(tab(true, false), { ...tab(false, true), tab: "b" }), {});
assert.deepEqual(wanted(tab(false, true), tab(true, true)), { nvim: true });
assert.deepEqual(wanted(tab(false, true, true), tab(true, true)), { nvim: false });
assert.deepEqual(wanted(tab(false, true), tab(false, false)), { panel: "show" });
assert.deepEqual(wanted(tab(true, false), tab(true, true)), {}, ":q keeps the panel");
assert.deepEqual(wanted(tab(true, true), tab(true, true)), {});

// The native Herdr runtime cannot be imported by Node. As upstream does,
// stand in for that boundary, with deliberately lagging app snapshots.
const stub = `data:text/javascript,${encodeURIComponent(`
  export const app = { spaces: [], panes: [], terminals: [], focused: null, layout: null, ran: [], shared: {}, calls: [] };
  export const spaces = () => app.spaces;
  export const panes = () => app.panes;
  export const terminals = () => app.terminals;
  export const focused = () => app.focused;
  export const layout = () => app.layout;
  export const home = () => app.home ?? "/tmp/filetree-test";
  export const shared = (key) => app.shared[key];
  export const setShared = (key, value) => { app.shared[key] = value; };
  export const notify = (n) => app.calls.push(["notify", n]);
  export const run = (name, args) => { app.ran.push([name, args]); app.run?.(name, args); };
  export const nextCommand = () => new Promise(() => {});
  export const exec = async (name, args) => { app.calls.push([name, args]); return app.exec(name, args); };
  export const hc = async (args) => { app.calls.push(["hc", args]); return app.hc(args); };
`)}`;
register(`data:text/javascript,${encodeURIComponent(`
  export async function resolve(spec, ctx, next) {
    if (spec === "herdr") return { url: ${JSON.stringify(stub)}, shortCircuit: true };
    return next(spec, ctx);
  }
`)}`);
const { app } = await import(stub);
const { panelState } = await import("../mods/filetree/panel.js");
const { Sync } = await import("../mods/filetree/sync.js");
const { editNvim } = await import("../mods/filetree/lib.js");
const files = { id: "files", type: "block", content: { mod: "filetree", props: { panel: true } } };
const stack = (active, hidden = false) => ({
  id: "root", children: [{ id: "panel", hidden, children: [{ id: "body", type: "stack", active, children: [files, { id: "changes" }] }] }],
});
assert.deepEqual(panelState(stack("files")), { stack: "body", slot: "files", panel: "panel", files: true, other: false });
assert.deepEqual(panelState(stack("changes")), { stack: "body", slot: "files", panel: "panel", files: false, other: true });
assert.equal(panelState(stack("files", true)).files, false);
assert.equal(panelState({ id: "root", children: [{ ...files }] }).files, true);
assert.equal(panelState({ id: "root", children: [] }), null);
assert.equal(panelState({ id: "sync", content: { mod: "filetree", props: { panel: true, role: "sync" } } }), null);

const ok = (stdout = "") => ({ code: 0, stdout, stderr: "" });
const cx = { spawn() {}, notify() {}, sleep: (ms) => new Promise((resolve) => setTimeout(resolve, ms)) };
const at = { space: "s", tab: "t", terminal: "t1", cwd: "/r" };
app.spaces = [{ id: "s", tabs: [{ id: "t" }], folder: "/r" }];
app.focused = { ...at, pane: "p1" };
app.panes = [{ pane: "p1", terminal: "t1", tab: "t" }];
app.exec = async (name) => ok(name === "git" ? "/r\n" : "");
app.hc = async () => {
  // The app lists a new terminal a moment after hc run starts it.
  setTimeout(() => { app.terminals = [{ address: "t9", state: "live", labels: { "filetree.nvim": "t" } }]; }, 20);
  return ok(JSON.stringify({ address: "t9" }));
};
const sync = new Sync(cx);
assert.equal((await sync.toggle(at, "open", cx)).terminal, "t9");
assert.equal(sync.nvimOf("t"), true, "just opened, not listed yet");
assert.ok(app.calls.find(([name, args]) => name === "hc" && args.includes("filetree.nvim=t") && args.includes("--bg")));
assert.deepEqual(app.ran.at(-1), ["terminal.keep", { terminal: "t9", place: "right" }]);
app.terminals = [{ address: "t9", state: "finished", labels: { "filetree.nvim": "t" } }];
assert.equal(sync.nvimOf("t"), false, "ended before it was ever listed live");
app.terminals = [];
sync.expect("t", { terminal: "t9" });
sync.tabState("t").expect.since -= 3500;
assert.equal(sync.nvimOf("t"), false, "never listed: the expectation runs out");
app.terminals = [{ address: "t9", state: "live", labels: { "filetree.nvim": "t" } }];
app.panes.push({ pane: "p9", terminal: "t9", tab: "t" });
assert.equal(sync.nvimOf("t"), true);
await sync.toggle(at, "close", cx);
assert.deepEqual(app.ran.at(-1), ["terminal.park", { terminal: "t9" }]);
assert.equal(sync.nvimOf("t"), false, "own close wins over lagging pane list");
app.panes.pop();
assert.equal(sync.nvimOf("t"), false, "parked nvim is not open");
app.ran = []; app.calls = [];
await sync.toggle(at, "open", cx);
assert.deepEqual(app.ran, [["terminal.keep", { terminal: "t9", place: "right" }]]);
assert.equal(app.calls.length, 0, "park/keep starts no process");

// A multi-pane tab focuses the rightmost own leaf BEFORE keeping nvim.
app.panes.push({ pane: "p2", terminal: "t2", tab: "t" });
app.run = (name, args) => { if (name === "pane.focus") app.focused.pane = args.pane; };
app.ran = [];
await sync.openFast(at, cx);
assert.deepEqual(app.ran, [["pane.focus", { pane: "p2" }], ["terminal.keep", { terminal: "t9", place: "right" }]]);
app.run = null;
app.panes.push({ pane: "p9", terminal: "t9", tab: "t" });
app.layout = stack("files", true);
app.ran = [];
const controller = new Sync(cx);
controller.look(cx);
controller.look(cx);
controller.look(cx);
app.layout = stack("files");
controller.look(cx);
assert.deepEqual(app.ran.map(([name]) => name), ["layout.select", "layout.show"], "own show must not be mistaken for closing Files");
await controller.reveal(cx, "recent");
assert.equal(app.shared["filetree.view"].view, "recent");
controller.focusTree();
assert.deepEqual(app.ran.slice(-2), [["pane.focus", { terminal: "t9" }], ["pane.go", { direction: "right" }]]);

// Open reuses the visible nvim and requests its panel, rather than a new terminal.
app.calls = []; app.ran = [];
await controller.open({ at, file: "/r/next file.md", root: "/r", rel: "next file.md" }, cx);
assert.equal(app.calls.filter(([name]) => name === "nvim").length, 1);
assert.equal(app.calls.some(([name]) => name === "hc"), false);
assert.deepEqual(app.ran.at(-1), ["pane.focus", { terminal: "t9" }]);
app.exec = async () => ({ code: 1, stdout: "", stderr: "server unavailable" });
await controller.open({ at, file: "/r/fail.md", root: "/r", rel: "fail.md" }, cx);
assert.equal(app.shared["filetree.preview"].rel, "fail.md", "failed nvim opens fall back to the in-panel preview");
await assert.rejects(editNvim("t", "/r/file.md"), /server unavailable/);
// A second action waits for our previous keep/park snapshot to catch up.
// Otherwise a quick file-open creates a duplicate, or a quick reopen loses nvim.
app.exec = async () => ok();
app.panes = [{ pane: "p1", terminal: "t1", tab: "t" }];
app.focused.pane = "p1";
app.calls = []; app.ran = [];
const lagged = new Sync(cx);
lagged.expect("t", { terminal: "t9" });
setTimeout(() => app.panes.push({ pane: "p9", terminal: "t9", tab: "t" }), 20);
assert.equal((await lagged.toggle(at, "open", cx)).terminal, "t9");
assert.equal(app.calls.length, 0, "pending keep must not create another nvim");
lagged.expect("t", { closed: "t9" });
setTimeout(() => app.panes.pop(), 20);
await lagged.toggle(at, "open", cx);
assert.deepEqual(app.ran.at(-1), ["terminal.keep", { terminal: "t9", place: "right" }]);

// cmd-o / cmd-shift-e without nvim: the tree shows and takes the keyboard
// from the rightmost pane; no nvim starts.
app.panes = [{ pane: "p1", terminal: "t1", tab: "t" }];
app.terminals = []; app.layout = stack("files", true);
app.calls = []; app.ran = [];
const bare = new Sync(cx);
await bare.reveal(cx, "recent");
assert.equal(app.calls.some(([name]) => name === "hc"), false, "reveal must not start nvim");
assert.deepEqual(app.ran.map(([name]) => name), ["layout.select", "layout.show"]);
assert.equal(bare.pendingFocus.terminal, "t1");

// Exercise the real nvim socket protocol too: filenames must stay data,
// including command separators, Vim key notation, quotes and newlines.
const { mkdtemp, mkdir, rm } = await import("node:fs/promises");
const { tmpdir } = await import("node:os");
const { join } = await import("node:path");
const { spawn, execFile } = await import("node:child_process");
const { promisify } = await import("node:util");
const command = promisify(execFile);
const root = await mkdtemp(join(tmpdir(), "filetree-nvim-"));
app.home = root;
const cache = join(root, ".cache", "herdr-filetree");
await mkdir(cache, { recursive: true });
const sock = join(cache, "nvim-live.sock");
const process = spawn("nvim", ["--clean", "-n", "--headless", "--listen", sock], { stdio: "ignore" });
const exited = new Promise((resolve, reject) => { process.once("exit", resolve); process.once("error", reject); });
const expression = async (expr) => (await command("nvim", ["--server", sock, "--remote-expr", expr])).stdout.trim();
try {
  let ready = false;
  for (let i = 0; i < 100 && !ready; i++) {
    try { await expression("1"); ready = true; }
    catch { await cx.sleep(20); }
  }
  assert.ok(ready, "real nvim listen socket did not become ready");
  app.exec = async (name, args) => ({ code: 0, ...(await command(name, args)) });
  for (const name of ["hello world.md", "quotes'\"%#|.md", "literal<CR><Esc>.md", "line\nbreak.md", "中文\\file.md"]) {
    const path = join(root, name);
    await editNvim("live", path);
    let actual;
    for (let i = 0; i < 100; i++) {
      actual = JSON.parse(await expression("json_encode(expand('%:p'))"));
      if (actual === path) break;
      await cx.sleep(10);
    }
    assert.equal(actual, path);
  }
  await command("nvim", ["--server", sock, "--remote-send", "<C-\\><C-n>:qa!<CR>"]);
  await exited;
} finally {
  process.kill();
  await exited;
  await rm(root, { recursive: true, force: true });
}
console.log("filetree sync checks: ok (including real nvim filename opens)");
