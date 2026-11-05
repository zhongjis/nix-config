// Workspace spaces: stable colored avatars, worktrees under their checkout,
// grouped by machine when more than one is known. After a space's name, the repo
// its first terminal is in now, only where unusual: branch, ahead/behind. Agent state lives in the agents list, not here,
// except a chip counting sub-agents (live and hibernated, space.js) that opens tui-subagents: on a shown worktree's
// row those working in it, on a space's row the rest working for that space. Click to
// switch, right-click for its menu, drag to reorder. A repo's worktrees go by their branch, folded behind a count
// on its row; the open ones bright, the rest dim (a click opens one as a space).

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { Repositories } from "./repos.js";
import { inSpace, spaceOf, matches } from "./space.js";
import { spaces, machines, panes, terminals, focused, keys, run, openOverlay, exec, hc, theme, shared, setShared, watchFolder, window, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// Where a space is now: its first terminal's live folder, else where it was made.
// `ps`: panes(), read once by the caller (each read copies every pane).
function place(s, ps) {
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}
const rowHeight = ({ tree }) => (tree ? 28 : 30);
const where = (s, ps) => JSON.stringify([s.machine ?? null, place(s, ps)]);
const base = (path) => path.replace(/\/+$/, "").split("/").pop();
// Changes made outside Herdr (an editor's save, a commit in another app): looked
// for this often, in repos the list shows, while the window is in front.
const FALLBACK = 60000;

// What a stored color name looks like on an avatar (the same in every mod that draws space avatars): the
// theme's own color of that name, or a color picked by hand.
const fill = (t, color) => (color.startsWith("#") ? color : t[color] ?? t.accent);
// Relative luminance of #rgb or #rrggbb, or null for anything else.
function luminance(c) {
  const hex = /^#[0-9a-f]{3}$/i.test(c ?? "") ? [...c.slice(1)].map((x) => x + x).join("") : /^#[0-9a-f]{6}/i.test(c ?? "") ? c.slice(1, 7) : null;
  if (!hex) return null;
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
// The theme's text color that reads best on a fill: its background or its foreground, whichever contrasts more.
function ink(t, color) {
  const l = luminance(color), contrast = (c) => {
    const m = luminance(c);
    return l == null || m == null ? 0 : (Math.max(l, m) + 0.05) / (Math.min(l, m) + 0.05);
  };
  return contrast(t.background) > contrast(t.foreground) ? t.background : t.foreground;
}
// tui-subagents' rows (live 50px, hibernated 32px) and padding: its popup's height for what it will list.
const subsHeight = (live, asleep) => Math.min(360, Math.max(46, 12 + 50 * live + 32 * asleep));

export default class Spaces extends View {
  init(_props, cx) {
    const panels = shared("workspace.panels") ?? ["files", "changes"];
    const missing = ["pr", "ci"].filter(id => !panels.includes(id));
    if (missing.length) setShared("workspace.panels", [...panels, ...missing]);
    this.repos = new Repositories();
    this.expanded = new Set(JSON.parse(localStorage.getItem("worktrees.expanded") ?? "[]"));
    this.git = {}; // where() -> { name, branch, ahead, behind, repo, linked }, null: not a repo
    this.checked = {}; // where() -> when it was last looked at
    this.unsure = new Set(); // where()s git couldn't answer for (a machine away)
    this.pending = new Set(); // where()s to look at next
    this.busy = {}; // pane -> an agent working or a program in front of its shell
    this.ready = {}; // machine -> its layout was readable at the last look
    this.at = {}; // space -> its where() at the last look
    this.watching = new Set(); // local repos' git folders
    // Spaces made while this runs wait (at most a moment) for their git, so a
    // worktree appears under its repo instead of jumping there.
    this.shown = new Set(spaces().map((s) => s.id));
    this.born = {};
    this.pressed = null;
    this.over = null;
    this.machines = [];
    this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
    for (const state of Object.values(this.reconnecting)) state.busy = false;
    this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]"));
    // Takes the keyboard while a row is dragged, so Esc can put it back.
    this.keys = cx.focus_handle();
    this.refreshMachines(cx);
    // Its redraw also brings round the fallback look in `due` (only while the window is in front).
    cx.timer.every(15000, cx => { if (window()?.active) this.refreshMachines(cx); });
  }

  // Called from render, which Herdr reruns whenever spaces, panes or agents change: a new space, a cd or a
  // finished command is seen as it happens. `git status` walks the whole tree, on another machine a process
  // there: only when its answer could have changed (see `due`).
  checkNew(cx) {
    const now = Date.now();
    const sp = spaces(), ps = panes();
    for (const s of sp) {
      if (this.shown.has(s.id) || this.born[s.id]) continue;
      this.born[s.id] = now;
      // Shown when its git answers (that redraws) or once ordered() stops waiting, whichever is first.
      cx.timer.after(1600, (cx) => cx.notify());
    }
    const due = this.due(now, sp, ps);
    if (due.size) this.refreshGit(due, cx);
    if (window()?.active) {
      const known = new Set(sp.map(s => this.git[where(s, ps)]?.repo));
      for (const g of Object.values(this.git)) if (g && known.has(g.repo)) this.repos.refresh(g, cx);
    }
  }

  // Ends a reorder drag and hands the keyboard back to the pane that had it (taken once the drag left its row).
  endDrag(restore = true) {
    const back = restore ? this.back : null;
    this.pressed = null;
    this.over = null;
    this.back = null;
    if (back?.pane) run("pane.focus", { pane: back.pane });
    else if (back?.terminal) run("pane.focus", { terminal: back.terminal });
  }

  // Places whose git could have changed: new ones (a new space, a cd), where a
  // command or an agent's turn just ended (a checkout, a commit, edits), those on
  // a machine that is back, and repos in view whose fallback is due.
  due(now, sp, ps) {
    // Moved there: what it knew of that place may be old.
    const at = {};
    for (const s of sp) at[s.id] = where(s, ps);
    const keys = new Set(Object.values(at).filter((k) => JSON.parse(k)[1]));
    const due = new Set([...keys].filter((k) => !(k in this.git)));
    for (const [id, k] of Object.entries(at)) if (this.at[id] && this.at[id] !== k && keys.has(k)) due.add(k);
    this.at = at;
    const spaceOf = {};
    for (const s of sp) for (const t of s.tabs ?? []) spaceOf[t.id] = s;
    const busy = {};
    for (const p of ps) {
      if (!p.terminal || !spaceOf[p.tab]) continue;
      busy[p.pane] = p.status === "working" || !(p.program?.shell || p.program?.agent);
      if (this.busy[p.pane] && !busy[p.pane]) this.sameRepo(at[spaceOf[p.tab].id], keys).forEach((k) => due.add(k));
    }
    this.busy = busy;
    for (const m of machines()) {
      const ready = m.layout === "ready";
      if (ready && this.ready[m.name] === false) for (const k of keys) if (JSON.parse(k)[0] === m.name) due.add(k);
      this.ready[m.name] = ready;
    }
    if (window()?.active) {
      for (const k of keys) {
        const asks = this.git[k] || this.unsure.has(k);
        if (asks && !this.folded.has(JSON.parse(k)[0]) && now - (this.checked[k] ?? 0) > FALLBACK) due.add(k);
      }
    }
    return due;
  }

  // `key` and the other places in its repo (a commit there moves their ahead/behind).
  sameRepo(key, keys) {
    const repo = this.git[key]?.repo;
    return [key, ...(repo ? [...keys].filter((k) => this.git[k]?.repo === repo) : [])];
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try { const r = await hc(["machine", "ls", "--json"]); if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary); } catch {}
      cx.notify();
    });
  }

  rebuilt(machine) {
    return machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? "");
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code !== 0) {
            let error;
            try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
            throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
          }
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add"];
        if (machine.via) args.push("--via", machine.target);
        else args.push(machine.target);
        args.push("--name", name);
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  // One look at a time, each place once however often it was asked for meanwhile.
  refreshGit(keys, cx) {
    for (const k of keys) this.pending.add(k);
    if (this.refreshing) return;
    this.refreshing = true;
    cx.spawn(async (cx) => {
      while (this.pending.size) {
        const keys = [...this.pending];
        this.pending.clear();
        for (const key of keys) await this.check(key, cx);
      }
      const used = new Set(Object.values(this.git).filter(Boolean).map((g) => JSON.parse(g.repo)).filter(([on]) => !on).map(([, repo]) => repo));
      for (const repo of this.watching) if (!used.has(repo)) this.watching.delete(repo);
      this.refreshing = false;
      cx.notify();
    });
  }

  // One place's git: branch, ahead/behind, its repo.
  async check(key, cx) {
    const [on, cwd] = JSON.parse(key);
    this.checked[key] = Date.now();
    this.unsure.delete(key);
    try {
      // No optional locks: a status that touched the index would wake the watch again.
      // Writes nothing under .git (index lock, fsmonitor cookie): watch() would wake on it.
      const r = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v2", "--branch"], { cwd, on });
      if (r.code !== 0) {
        // Only git's own "no" is remembered as no repo; anything else is asked again.
        if (!/not a git repository/i.test(r.stderr)) this.unsure.add(key);
        this.git[key] = null;
        return;
      }
      // The repo's own .git folder names it; a worktree's top differs from it.
      const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
      const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd, on });
      const repo = common.stdout.trim();
      const name = repo.endsWith("/.git") ? base(repo.slice(0, -5)) : base(repo).replace(/\.git$/, "");
      const info = { name, folder: top.stdout.trim(), branch: null, ahead: 0, behind: 0, repo: JSON.stringify([on, repo]), linked: repo !== `${top.stdout.trim()}/.git` };
      for (const line of r.stdout.split("\n")) {
        if (line.startsWith("# branch.head ")) info.branch = line.slice(14);
        else if (line.startsWith("# branch.ab ")) {
          const [a, b] = line.slice(12).split(" ");
          info.ahead = Math.abs(parseInt(a, 10)) || 0;
          info.behind = Math.abs(parseInt(b, 10)) || 0;
        }
      }
      this.git[key] = info;
      if (!on) this.watch(repo, cx);
      if (window()?.active || !this.repos.groups[info.repo]) this.repos.refresh(info, cx);
    } catch {
      // Couldn't ask (the machine is away): keep what it showed, look again later.
      this.git[key] ??= null;
      this.unsure.add(key);
    }
  }

  watch(repo, cx) {
    if (this.watching.has(repo)) return;
    this.watching.add(repo);
    cx.spawn(async (cx) => {
      try {
        while (this.watching.has(repo)) {
          await watchFolder(repo);
          const mine = JSON.stringify([null, repo]);
          if (this.watching.has(repo)) this.refreshGit(Object.keys(this.git).filter((k) => this.git[k]?.repo === mine), cx);
        }
      } catch { this.watching.delete(repo); }
    });
  }

  menu(w) {
    // A popup is as tall as its items; height is only the most.
    openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: w.id } } });
  }

  // Spaces in order, each worktree space moved under its main checkout's.
  ordered() {
    const sp = spaces(), ps = panes();
    const ready = (w) => this.shown.has(w.id) || where(w, ps) in this.git || Date.now() - (this.born[w.id] ??= Date.now()) > 1500;
    for (const w of sp) if (!this.shown.has(w.id) && ready(w)) this.shown.add(w.id);
    const list = sp.map((w, i) => ({ w, i, g: this.git[where(w, ps)] ?? null })).filter((r) => this.shown.has(r.w.id));
    const out = [], placed = new Set();
    for (const r of list) {
      if (!r.g) { out.push(r); continue; }
      if (placed.has(r.g.repo)) continue;
      placed.add(r.g.repo);
      const group = list.filter(k => k.g?.repo === r.g.repo);
      // Without a main-checkout space, the first worktree space is the head.
      const head = group.find(k => !k.g.linked) ?? group[0];
      const top = { ...head, tree: null };
      out.push(top);
      group.filter(k => k !== head && !k.g.linked).forEach(k => out.push({ ...k, tree: null }));
      const kids = group.filter(k => k !== head && k.g.linked).map(k => ({ ...k, tree: "└─" }));
      const all = this.repos.groups[r.g.repo]?.worktrees ?? [];
      for (const wt of all) {
        if (group.some(k => k.g.folder === wt.folder)) continue;
        kids.push({ w: { id: wt.folder, name: wt.branch ?? base(wt.folder), machine: r.w.machine }, g: { ...r.g, ...wt, ahead: 0, behind: 0 }, tree: "└─", vacant: true });
      }
      if (kids.length) {
        Object.assign(top, { count: new Set(kids.map(k => k.g.folder)).size, failed: kids.some(k => this.repos.pr(k.g)?.ci === "fail"), open: this.expanded.has(r.g.repo) });
        out.push(...kids.filter(k => top.open || k.w.active));
      }
    }
    return out;
  }

  // The rows, under a header per machine once one isn't this computer.
  grouped(t, collapsed) {
    // The rail has no room for worktrees without a space.
    const rows = this.ordered().filter(r => !(collapsed && r.vacant));
    this.subs = this.subFilters(rows);
    const draw = r => r.vacant ? this.vacant(r, t) : collapsed ? this.compact(r, t) : this.row(r, t);
    const remote = [...new Set([...rows.map(r => r.w.machine).filter(Boolean), ...this.machines.map(m => m.name), ...Object.keys(this.reconnecting)])].sort();
    const loading = m => {
      const layout = machines().find(k => k.name === m)?.layout;
      return layout === "loading" || (!layout && this.machines.some(k => k.name === m && k.state === "connected"))
        || spaces().some(s => (s.machine ?? null) === m && !this.shown.has(s.id));
    };
    const loadingRow = m => div().id(`machine-loading-${m ?? "local"}`).h(28).flex_none().px(8).text_size(12).text_color(t.dim).child(collapsed ? "…" : "Loading…");
    if (!remote.length) return loading(null) && !rows.length ? [loadingRow(null)] : rows.map(draw);
    const machineNames = [null, ...remote];
    return machineNames.flatMap((m) => {
      const mine = rows.filter((r) => (r.w.machine ?? null) === m);
      const repair = this.reconnecting[m];
      const machine = this.machines.find(k => k.name === m) ?? repair?.machine;
      const connected = !m || machine?.state === "connected";
      const rebuilt = this.rebuilt(machine) || !!repair;
      const folded = this.folded.has(m);
      // The state in words, for the dot's tooltip.
      const said = connected ? "connected" : (machine?.state ?? "asleep").replace(/_/g, " "), state = said[0].toUpperCase() + said.slice(1);
      const head = h_flex().id(`machine-${m ?? "local"}`).h(26).flex_none().px(collapsed ? 2 : 8).gap(7).items_center().text_size(11).text_color(t.dim)
        .cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => {
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${m ? "server" : "monitor"}.svg`).size(13).flex_none())
        .when(!collapsed, el => el.child(div().flex_1().truncate().child(m ?? "This computer"))
          .when(!connected && !rebuilt, el => el.child(div().flex_none().child(said)))
          .when(rebuilt, el => el.child(h_flex().flex_none().gap(3).items_center()
            .child(div().max_w(140).truncate().child(repair?.error || "rebuilt ·"))
            .child(div().id(`machine-connect-${m}`).h(22).px(6).flex().items_center().rounded(5).text_color(repair?.error ? t.blocked : t.muted)
              .cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
              .tooltip(repair?.error || "This machine was rebuilt or replaced. Click to connect to the new one.")
              .on_click((_e, cx) => { cx.stop_propagation(); this.reconnect(machine, cx); })
              .child(repair?.busy ? "Connecting…" : "Connect"))))
          .when(connected, el => el.child(div().id(`machine-add-${m ?? "local"}`).size(24).flex_none().flex().items_center().justify_center().rounded(6)
            .cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip(`New space on ${m ?? "this computer"}`)
            .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: m ?? "" }); })
            .child(svg("mods/workspace-chrome/plus.svg").size(14))))
          .child(div().id(`machine-state-${m ?? "local"}`).size(6).rounded(3).flex_none().bg(connected ? t.done : t.dim).tooltip(state))
          .child(svg(`mods/workspace-chrome/chevron-${folded ? "right" : "down"}.svg`).size(11).flex_none()));
      const empty = h_flex().id(`machine-new-${m ?? "local"}`).h(28).flex_none().px(8).gap(7).items_center().rounded(7)
        .text_size(12).text_color(t.dim).cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => run("space.new", { machine: m ?? "" }))
        .child(svg("mods/workspace-chrome/plus.svg").size(12)).when(!collapsed, el => el.child("New space there"));
      if (!collapsed && rebuilt) return [head];
      return [head, ...(folded ? [] : mine.length ? mine.map(draw) : [loading(m) ? loadingRow(m) : empty])];
    });
  }

  // Only what's unusual, after the name: "herdr \u00b7 spike \u21912 \u21931". The repo or
  // branch goes when the name already says it (a worktree is named after its branch),
  // and master/main go: nearly every space is on one.
  gitWhere(g, tree, name) {
    if (!g) return "";
    const raw = g.branch ?? "detached";
    const same = (a) => a.toLowerCase() === name.toLowerCase();
    const branch = same(raw) || raw === "master" || raw === "main" ? "" : raw;
    const repo = tree || same(g.name) ? "" : g.name;
    return [repo, branch].filter(Boolean).join(" \u00b7 ");
  }

  // Ahead/behind stay on the name line; repo/branch go on their own line below.
  gitTail(g, t) {
    return h_flex()
      .flex_none()
      .gap(5)
      .items_center()
      .text_size(11)
      .text_color(t.dim)
      .when(g.ahead > 0, (el) => el.child(div().flex_none().text_color(t.ansi2).child(`\u2191${g.ahead}`)))
      .when(g.behind > 0, (el) => el.child(div().flex_none().text_color(t.ansi1).child(`\u2193${g.behind}`)));
  }

  badge(g, t) {
    const pr = this.repos.pr(g);
    if (!pr) return div();
    // CI as a mark that reads without its color: passed, failed, running.
    const ci = { pass: ["check", t.done], fail: ["cross", t.blocked], pending: ["pending", t.working] }[pr.ci];
    return h_flex().id(`pr-${g.repo}-${g.folder}-${pr.number}`).flex_none().h(22).gap(3).px(6).items_center().rounded(5).text_size(11).text_color(t.muted)
      .cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
      .tooltip(pr.title)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_mouse_up("left", (_e, cx) => {
        cx.stop_propagation();
        setShared("pr.select", { repo: pr.repo, number: pr.number, at: Date.now() });
        run("layout.select", { stack: "panel-body", child: "pr" });
        run("layout.show", { id: "panel" });
      })
      .child(`#${pr.number}`)
      .when(Boolean(ci), el => el.child(svg(`mods/pr-flow/${ci?.[0]}.svg`).size(11).flex_none().text_color(ci?.[1])));
  }

  // A branch with its prefix ("feat/") dimmed, so the part that names the work reads first.
  branchLabel(branch, color, t) {
    const cut = branch.lastIndexOf("/") + 1;
    return h_flex().min_w(0).flex_shrink(1).text_color(color)
      .when(cut > 0, el => el.child(div().flex_none().text_color(t.dim).child(branch.slice(0, cut))))
      .child(div().min_w(0).truncate().child(branch.slice(cut)));
  }

  // On a repo's row: a chevron that folds or unfolds its worktrees. Folded, a failing PR among them shows
  // here, since its own row is hidden.
  worktreeChip(r, t) {
    const alarm = r.failed && !r.open;
    return h_flex().id(`worktrees-${r.g.repo}`).flex_none().h(22).gap(3).px(6).items_center().rounded(5).text_size(11)
      .text_color(alarm ? t.blocked : t.dim).cursor_pointer().hover(s => s.bg(t.hover).text_color(alarm ? t.blocked : t.foreground))
      .tooltip(`${r.count} worktree${r.count > 1 ? "s" : ""}${alarm ? ", CI failing on one" : ""}`)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_mouse_up("left", (_e, cx) => {
        cx.stop_propagation();
        r.open ? this.expanded.delete(r.g.repo) : this.expanded.add(r.g.repo);
        localStorage.setItem("worktrees.expanded", JSON.stringify([...this.expanded]));
        cx.notify();
      })
      .when(alarm, el => el.child(svg("mods/pr-flow/cross.svg").size(11).flex_none()))
      .child(svg(`mods/workspace-chrome/chevron-${r.open ? "down" : "right"}.svg`).size(10).flex_none());
  }

  // Each row's sub-agent filter (space.js), read once per render: a shown worktree row takes those working in its
  // folder; a space row the rest of that space's. `rows` are the drawn rows.
  subFilters(rows) {
    const all = terminals(), byAddress = new Map(all.map((k) => [k.address, k]));
    const sleeping = shared("tui-focus.hibernated") ?? [];
    const count = (f) => [inSpace(all, f).length, sleeping.filter((r) => matches(r.space ?? spaceOf({ parent: r.parent }, byAddress), r.cwd, f)).length];
    const trees = rows.filter((r) => r.tree && r.g?.folder).map((r) => r.g.folder);
    const out = new Map();
    for (const r of rows) {
      const f = r.tree && r.g?.folder ? { folder: r.g.folder } : r.vacant ? null : { space: r.w.id, except: trees };
      const [live, asleep] = f ? count(f) : [0, 0];
      if (live + asleep) out.set(r, { filter: f, n: live + asleep, live, asleep });
    }
    return out;
  }

  // How many sub-agents a row counts; a click lists them (tui-subagents), to peek at or revive.
  subChip(w, { filter, n, live, asleep }, t) {
    return h_flex().id(`subs-${w.id}`).flex_none().h(22).gap(3).px(6).items_center().rounded(5).text_size(11).text_color(t.dim)
      .cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
      .role("button").accessibility_label("Show workers")
      .tooltip(`${n} worker${n > 1 ? "s" : ""}`)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_mouse_up("left", (_e, cx) => {
        cx.stop_propagation();
        openOverlay({ mod: "tui-subagents", kind: "popup", width: 300, height: subsHeight(live, asleep), props: { filter } });
      })
      .child(svg("icons/agent.svg").size(12).flex_none())
      .child(String(n));
  }

  // A worktree without a space: the same line as an open one, dimmed; a click opens it.
  vacant(r, t) {
    const { w, g } = r;
    return h_flex().id(`worktree-${g.repo}-${g.folder}`).h(28).flex_none().px(8).gap(9).items_center().rounded(8).cursor_pointer().hover(s => s.bg(t.hover))
      .tooltip(`Open ${base(g.folder)} as a space`)
      .on_click(() => run("space.new", { folder: g.folder, machine: w.machine ?? "" }))
      .child(h_flex().pl(22).flex_none().child(svg("mods/workspace-chrome/branch.svg").size(13).text_color(t.dim)))
      .child(this.branchLabel(g.branch ?? w.name, t.muted, t))
      .child(div().flex_1())
      .when(Boolean(this.subs?.get(r)), el => el.child(this.subChip(w, this.subs.get(r), t)))
      .child(this.badge(g, t));
  }

  // A space's avatar: its color, and on it `label` in whichever theme text color reads best there.
  avatar(w, t, label) {
    const color = fill(t, (shared("space.colors") ?? {})[w.id] ?? "ansi6");
    return h_flex().size(18).flex_none().rounded(5).bg(color).items_center().justify_center().text_size(11).font_bold().text_color(ink(t, color)).child(label);
  }

  row(r, t) {
    const { w, i, g, tree } = r;
    const on = w.active;
    // A worktree goes by its branch; a name the person gave its space comes first, the branch under it.
    const branch = tree ? g?.branch ?? null : null;
    const own = Boolean(branch) && w.named && w.name !== branch;
    const where = tree ? (own ? branch : "") : this.gitWhere(g, tree, w.name);
    const subs = this.subs?.get(r);
    return v_flex()
      .relative()
      .id(`space-${w.id}`)
      .px(8)
      .h(rowHeight({ tree }) + (where ? 16 : 0))
      .flex_none()
      .justify_center()
      .rounded(8)
      .cursor_pointer()
      .when(on, (el) => el.bg(t.selected))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .when(this.pressed === i && this.over !== i, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === i && this.pressed !== i, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(this.pressed < i, line => line.bottom(0))
          .when(this.pressed > i, line => line.top(0)),
      ))
      .on_mouse_down("left", () => {
        this.pressed = i;
        this.over = i;
      })
      .on_mouse_move((_e, cx) => {
        if (this.pressed === null) return;
        const source = spaces()[this.pressed];
        const over = source && (source.machine ?? null) === (w.machine ?? null) ? i : null;
        // Off its own row it's a drag: the sidebar takes the keyboard, so Esc can put it back.
        if (i !== this.pressed && !this.back) {
          this.back = focused();
          this.keys.focus();
        }
        if (this.over !== over) {
          this.over = over;
          cx.notify();
        }
      })
      .on_mouse_up("left", (_e, cx) => {
        const from = this.pressed;
        const over = this.over;
        if (from !== null && over === i && from !== i) {
          this.endDrag();
          run("space.move", { id: spaces()[from].id, index: i + 1 });
        } else if (from === i) {
          this.endDrag(false);
          run("space.select", { id: w.id });
        } else this.endDrag();
        cx.notify();
      })
      .on_mouse_down("right", () => this.menu(w))
      .child(
        h_flex()
          .gap(9)
          .items_center()
          .when(Boolean(tree), el => el.pl(22).child(svg("mods/workspace-chrome/branch.svg").size(13).text_color(t.dim)))
          .when(!tree, el => el.child(this.avatar(w, t, [...w.name][0]?.toUpperCase() ?? "?")))
          // The name gives way first when the row is short of room; what follows it keeps its size.
          .child(branch && !own ? this.branchLabel(branch, t.foreground, t) : div().min_w(0).truncate().text_color(t.foreground).child(w.name))
          .child(div().flex_1())
          .when(Boolean(g?.ahead || g?.behind), el => el.child(this.gitTail(g, t)))
          .child(this.badge(g, t))
          .when(Boolean(subs), el => el.child(this.subChip(w, subs, t)))
          .when(Boolean(r.count), el => el.child(this.worktreeChip(r, t))),
      )
      .when(Boolean(where), (el) => el.child(
        div().pl(tree ? 44 : 27).min_w(0).truncate().text_size(11).text_color(t.dim).child(where),
      ));
  }

  // The rail: each space's avatar color, with its number on it; its name on hover.
  compact({ w, i, g }, t) {
    return h_flex()
      .id(`space-${w.id}`)
      .h(26)
      .flex_none()
      .justify_center()
      .items_center()
      .gap(4)
      .cursor_pointer()
      .when(w.active, (el) => el.bg(t.raised))
      .hover((s) => s.bg(w.active ? t.raised : t.hover))
      .tooltip(w.name)
      .on_click(() => run("space.select", { id: w.id }))
      .child(this.avatar(w, t, String(i + 1)))
      .child(this.badge(g, t));
  }

  render(cx) {
    const t = theme();
    const collapsed = narrow();
    this.checkNew(cx);
    const palette = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
    const sp = spaces();
    const ids = new Set(sp.map(p => p.id));
    const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
    let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
    for (const p of sp) {
      if (kept[p.id] || p.name === "~") continue;
      const uses = c => Object.values(kept).filter(v => v === c).length;
      kept[p.id] = palette.reduce((best, c) => uses(c) < uses(best) ? c : best);
      changed = true;
    }
    if (changed) setShared("space.colors", kept);
    const newKey = keys().find((b) => b.section === "global" && b.action === "space.new")?.keys;
    return v_flex().id("spaces-root").size_full().min_h(0).bg(t.chrome).text_size(13)
      // Esc puts a dragged row back (the sidebar holds the keyboard only while one is dragged).
      .track_focus(this.keys).on_key_down((e, cx) => {
        if (e.key !== "escape" || this.pressed === null) return;
        this.endDrag();
        cx.notify();
      })
      .child(h_flex().h(31).pl(16).pr(10).items_center().justify_between().text_size(12).text_color(t.dim)
        .when(!collapsed, el => el.child("Spaces"))
        .child(div().id("space-new").size(26).flex_none().flex().items_center().justify_center().rounded(6)
          .cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip(newKey ? `New space  ${newKey}` : "New space")
          .on_click(() => run("space.new")).child(svg("mods/workspace-chrome/plus.svg").size(14))))
      .child(v_flex().id("spaces-list").flex_1().min_h(0).px(8).pb(14).overflow_y_scrollbar().mode("always")
        // Released anywhere in the list, or the pointer leaving it (Herdr reports no release outside), ends a drag.
        .on_mouse_up("left", (_e, cx) => { if (this.pressed === null) return; this.endDrag(); cx.notify(); })
        .on_hover((on, cx) => { if (on || this.pressed === null) return; this.endDrag(); cx.notify(); })
        .children(this.grouped(t, collapsed)));
  }
}
