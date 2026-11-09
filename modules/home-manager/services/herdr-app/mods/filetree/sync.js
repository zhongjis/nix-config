// The controller that makes the Files panel and the tab's nvim pane one
// feature. It lives in an empty floating block (always on screen, no size),
// so it sees every change: a hidden block's mod is not rendered at all.
// Vendored from ChmaraX/herdr-nvim (MIT; LICENSE-herdr-nvim), trimmed to
// the native tree and a real nvim per tab, without preview swaps or Rust.
//
// One rule, applied to whatever changed last:
// - the shown tab changed: the panel shows if that tab's nvim does; a tab
//   without nvim keeps the panel as it is. nvim panes are per tab, the
//   panel is per window.
// - Files opened: nothing; nvim starts only for a file opened from the tree.
// - Files closed: a shown nvim is PARKED with it (Changes leaves it open);
//   the next file opened KEEPS it back.
// - nvim appeared (a file opened): the panel shows. nvim went (`:q`): the
//   panel stays.
//
// Each action makes the other side agree, so the next look finds nothing
// to do: no loops. While an action runs nothing else is decided, and until
// the terminal list shows its result, the result is assumed (the list lags
// the command by a moment). What it knows of each tab is one tabState.

import { focused, layout, nextCommand, notify, panes, run, setShared, shared, spaces, terminals } from "herdr";
import { editNvim, place, startNvim } from "./lib.js";
import { wanted } from "./sync-rule.js";
import { ended, goToTree, nvimPanes, ownPanes, panelState, parkedNvim, showFiles } from "./panel.js";

const WAIT_MS = 5000;
const EXPECT_MS = 3000;

export class Sync {
  constructor(cx) {
    this.tabs = new Map();
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        try {
          if (command === "reveal") await this.reveal(cx);
          else if (command === "recent") await this.reveal(cx, "recent");
          else if (command.startsWith("open:")) await this.open(JSON.parse(decodeURIComponent(command.slice(5))), cx);
        } catch (e) {
          notify({ title: "filetree", body: String(e?.message ?? e), level: "error" });
        }
      }
    });
  }

  tabState(tab) {
    let t = this.tabs.get(tab);
    if (!t) this.tabs.set(tab, (t = { expect: null }));
    return t;
  }

  expect(tab, made) {
    this.tabState(tab).expect = {
      opened: made.terminal ?? null,
      closed: made.closed ?? null,
      since: Date.now(),
    };
  }

  nvimOf(tab) {
    const seen = nvimPanes(tab), t = this.tabState(tab), e = t.expect;
    if (e && Date.now() - e.since > EXPECT_MS) t.expect = null;
    else if (e) {
      if (e.opened && !seen.includes(e.opened) && !ended(e.opened)) return true;
      if (e.closed && seen.includes(e.closed)) return seen.length > 1;
      t.expect = null;
    }
    return seen.length > 0;
  }

  look(cx) {
    this.focusTree();
    this.endOrphans();
    if (this.busy) return;
    const p = panelState(layout()), f = focused();
    if (!p || !f?.tab) return;
    const to = this.panelWant;
    if (to && p.files !== to.files && Date.now() - to.since <= EXPECT_MS) return;
    this.panelWant = null;
    const cur = { tab: f.tab, at: place(f), files: p.files, other: p.other, nvim: this.nvimOf(f.tab) };
    const prev = this.prev;
    if (prev && prev.tab !== cur.tab) this.forgetGoneTabs();
    this.prev = cur;
    const want = wanted(cur, prev);
    if (want.panel === "show") { this.panelTo(true, () => showFiles(p)); cur.files = true; }
    if (want.nvim) this.act(cur, cx);
  }

  panelTo(files, change) {
    this.panelWant = { files, since: Date.now() };
    change();
  }

  forgetGoneTabs() {
    const known = new Set(spaces().flatMap((s) => s.tabs.map((t) => t.id)));
    for (const tab of this.tabs.keys()) if (!known.has(tab)) this.tabs.delete(tab);
  }

  // Closing a tab stops its nvim, parked or shown (upstream: the tab's
  // daemon ends with it). Nothing to do until a tab is gone.
  endOrphans() {
    const known = new Set(spaces().flatMap((s) => s.tabs.map((t) => t.id)));
    if (!known.size) return;
    this.killed ??= new Set();
    for (const t of terminals()) {
      const tab = t.labels?.["filetree.nvim"];
      if (t.state !== "live" || !tab || known.has(tab) || this.killed.has(t.address)) continue;
      this.killed.add(t.address);
      run("terminal.kill", { terminal: t.address });
    }
  }

  act(cur, cx) {
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        const state = cur.files ? "open" : "close";
        if (state === "open" ? !cur.nvim : cur.nvim) await this.toggle(cur.at, state, cx);
        cur.nvim = state === "open";
      } catch (e) {
        notify({ title: "filetree", body: `Could not open or close the tab's nvim: ${e?.message ?? e}`, level: "error" });
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  async toggle(at, state, cx) {
    // Do not mistake our own pending keep for no nvim (and start a second
    // one), or a pending park for a shown nvim that needs no keep.
    const pending = this.tabState(at.tab).expect;
    if (pending) {
      const applied = () => pending.opened
        ? nvimPanes(at.tab).includes(pending.opened) || ended(pending.opened)
        : !nvimPanes(at.tab).includes(pending.closed);
      if (!(await this.until(applied, EXPECT_MS, cx))) throw new Error("nvim's last pane change is still pending");
      this.tabState(at.tab).expect = null;
    }
    if (state === "close") {
      const terminal = nvimPanes(at.tab)[0];
      if (terminal) {
        run("terminal.park", { terminal });
        this.expect(at.tab, { closed: terminal });
      }
      return { closed: terminal };
    }
    const fast = await this.openFast(at, cx);
    if (fast) { this.expect(at.tab, fast); return fast; }
    // The address comes directly from hc run --json, not the lagging
    // terminals() snapshot. terminal.keep adopts it into the focused tab.
    const terminal = await startNvim(at, at.file);
    // terminal.keep ignores a terminal the app has not listed yet.
    if (!(await this.until(() => terminals().some((t) => t.address === terminal), EXPECT_MS, cx))) throw new Error("nvim's terminal did not appear");
    const own = ownPanes(at.tab).at(-1);
    if (!own || !(await this.focusPane(own.pane, cx))) throw new Error("Could not focus the tab's rightmost pane");
    run("terminal.keep", { terminal, place: "right" });
    this.expect(at.tab, { terminal });
    return { terminal, started: true };
  }

  // There is no versioned Rust UI: an existing labelled nvim is always
  // reusable, including after this JS build reloads.
  fresh(terminal) { return Boolean(terminal); }

  async until(ready, ms, cx) {
    for (const end = Date.now() + ms; !ready(); ) {
      if (Date.now() > end) return false;
      await cx.sleep(10);
    }
    return true;
  }

  async focusPane(pane, cx) {
    if (focused()?.pane !== pane) run("pane.focus", { pane });
    return this.until(() => focused()?.pane === pane, 500, cx);
  }

  // Pane order is layout order. The last own leaf is on the right edge;
  // keeping beside it also works when the tab has several own panes.
  async openFast(at, cx) {
    const shown = nvimPanes(at.tab)[0];
    if (shown) return { terminal: shown, started: false };
    const own = ownPanes(at.tab).at(-1), parked = parkedNvim(at.tab);
    if (!this.fresh(parked)) return null;
    if (!own || !(await this.focusPane(own.pane, cx))) throw new Error("Could not focus the tab's rightmost pane");
    run("terminal.keep", { terminal: parked, place: "right" });
    return { terminal: parked, started: false };
  }

  async open(request, cx) {
    let acting = false;
    try {
      for (const until = Date.now() + WAIT_MS; this.busy && Date.now() < until; ) await cx.sleep(100);
      if (this.busy) throw new Error("Still opening nvim; try the file again");
      if (focused()?.tab !== request.at.tab) return;
      this.busy = acting = true;
      const made = await this.toggle({ ...request.at, cwd: request.root, file: request.file }, "open", cx);
      if (!(await this.until(() => nvimPanes(request.at.tab).includes(made.terminal), EXPECT_MS, cx))) throw new Error("nvim's pane did not appear");
      if (!made.started) await editNvim(request.at.tab, request.file);
      const p = panelState(layout());
      if (p && focused()?.tab === request.at.tab) this.panelTo(true, () => showFiles(p));
      run("pane.focus", { terminal: made.terminal });
    } catch (e) {
      notify({ title: "Could not open the file", body: String(e?.message ?? e), level: "error", timeout: 4000 });
      setShared("filetree.preview", { root: request.root, rel: request.rel, n: Date.now() });
    } finally {
      if (acting) this.busy = false;
      cx.notify();
    }
  }

  async reveal(cx, view = "tree") {
    const f = focused(), p = panelState(layout());
    if (!f?.tab || !p || this.busy) return;
    this.busy = true;
    try {
      // `pane.go` right reaches the tree from nvim, else from the rightmost
      // pane; showing the tree starts no nvim.
      const terminal = nvimPanes(f.tab)[0] ?? ownPanes(f.tab).filter((x) => x.terminal).at(-1)?.terminal;
      setShared("filetree.view", { view, n: (shared("filetree.view")?.n ?? 0) + 1 });
      if (!p.files) this.panelTo(true, () => showFiles(p));
      this.prev = { tab: f.tab, files: true, other: false, nvim: this.nvimOf(f.tab) };
      if (terminal) this.pendingFocus = { terminal, tab: f.tab, since: shared("filetree.tree-laid-out") ?? 0, shown: p.files };
    } finally {
      this.busy = false;
      cx.notify();
    }
  }

  focusTree() {
    const want = this.pendingFocus;
    if (!want) return;
    if (focused()?.tab !== want.tab) { this.pendingFocus = null; return; }
    if (!want.shown && (shared("filetree.tree-laid-out") ?? 0) === want.since) return;
    if (!panes().some((x) => x.tab === want.tab && x.terminal === want.terminal)) return;
    this.pendingFocus = null;
    goToTree(want.terminal);
  }
}
