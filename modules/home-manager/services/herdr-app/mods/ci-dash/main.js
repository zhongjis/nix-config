// CI Dash for the Herdr app: GitHub Actions runs, dispatch and artifacts of the
// focused repository. Port of the ci-dash TUI plugin.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, v_virtual_list, VirtualListScrollHandle, Scrollbar } from "gpui-base";
import { spaces, panes, focused, exec, home, theme, notify, props, shared, layout, window as appWindow } from "herdr";
import { Gh, resolveRepo, errorHint, safeName } from "./gh.js";
import { relTime, duration, bytes, stateOf, mapLimit, fileType, GLYPH } from "./format.js";
import { Dispatch } from "./dispatch.js";
import { MOD, icon, pill, section, SECTION_H, searchBox, filterChip, busy, backLink } from "./ui.js";

const POLL_MS = 5000;
const RUN_ROW_H = 62;
const TABS = ["runs", "dispatch", "artifacts"];

// Runs are grouped by what the person has to do about them.
const RUN_GROUPS = [
  { id: "live", label: "In progress", filter: "Running", color: (t) => t.working },
  { id: "attention", label: "Needs attention", filter: "Failed", color: (t) => t.ansi1 },
  { id: "passed", label: "Passed", filter: "Passed", color: (t) => t.ansi2 },
  { id: "other", label: "Other", filter: "Other", color: (t) => t.dim },
];
const groupOf = (run) => {
  const kind = stateOf(run).kind;
  if (kind === "running" || kind === "queued") return "live";
  if (kind === "failure" || kind === "warning") return "attention";
  return kind === "success" ? "passed" : "other";
};

const ART_GROUPS = [
  { id: "available", filter: "Available", color: (t) => t.accent },
  { id: "downloaded", filter: "Downloaded", color: (t) => t.ansi2 },
  { id: "expired", filter: "Expired", color: (t) => t.ansi1 },
];

const isWin = () => /^[A-Za-z]:[\\/]/.test(home());
const sep = (root) => (root.includes("\\") ? "\\" : "/");
const join = (root, ...parts) => [root.replace(/[\\/]+$/, ""), ...parts].join(sep(root));

let lastCwd = null;

// The panel copy (props.panel) sits in a stack that can show another child, in a column that
// can be hidden. A layout without such a block counts as shown.
function onScreen() {
  const root = layout();
  const mine = (n) => n?.content?.mod === MOD && Boolean(n.content.props?.panel);
  const has = (n) => mine(n) || (n?.children ?? []).some(has);
  const shown = (n) => !n.hidden && (mine(n)
    || (n.children ?? []).some((c) => (n.type !== "stack" || (n.active ?? n.children[0]?.id) === c.id) && shown(c)));
  return !has(root) || shown(root);
}

// A mod pane has no folder of its own, so look at the terminals around it:
// the focused pane, then its tab, then the rest of its space. The last folder
// found stays as a fallback so clicking this panel never loses the repository.
function location() {
  const f = focused();
  const space = spaces().find((s) => s.id === f?.space) || spaces().find((s) => s.active);
  const all = panes();
  const pane = f?.pane ? all.find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  const inTab = all.find((p) => p.tab === f?.tab && p.cwd)?.cwd;
  const spaceTabs = new Set((space?.tabs ?? []).map((tab) => tab.id));
  const inSpace = all.find((p) => spaceTabs.has(p.tab) && p.cwd)?.cwd;
  const cwd = pane?.cwd || f?.cwd || inTab || inSpace || lastCwd || space?.folder;
  if (pane?.cwd || f?.cwd || inTab || inSpace) lastCwd = cwd;
  // The branch is the one shown next to the folder that was chosen.
  const branch = (pane?.cwd ? pane : all.find((p) => p.cwd === cwd && p.branch))?.branch || null;
  return { cwd, on, branch };
}

// gh's and git's own wording for the common "nothing to show here" cases, said plainly.
function friendlyError(text) {
  if (/not a git repository/i.test(text)) return { title: "This folder is not a git repository.", hint: "Focus a terminal inside a repository that has a GitHub remote, and CI runs follows it." };
  if (/no git remotes|none of the git remotes|could not determine.*repo/i.test(text)) return { title: "This repository has no GitHub remote.", hint: "Add one with git remote add origin <url>, or focus a terminal in another repository." };
  if (/Could not resolve to a Repository/i.test(text)) return { title: "None of your GitHub logins can see this repository.", hint: "Log in with an account that has access: gh auth login, then press r or Refresh." };
  if (/not logged in|gh auth login/i.test(text) && !/Could not start gh/.test(text)) return { title: "GitHub CLI is not logged in.", hint: "Run gh auth login in a terminal, then press r or Refresh." };
  return null;
}

async function dirExists(dir, on) {
  try {
    const r = isWin()
      ? await exec("pwsh", ["-NoProfile", "-Command", `Test-Path -LiteralPath '${dir.replace(/'/g, "''")}' -PathType Container`], { on })
      : await exec("test", ["-d", dir], { on });
    return isWin() ? r.stdout.trim() === "True" : r.code === 0;
  } catch { return false; }
}

async function openFolder(dir) {
  const [cmd, args] = isWin() ? ["explorer.exe", [dir]] : home().startsWith("/Users/") ? ["open", [dir]] : ["xdg-open", [dir]];
  await exec(cmd, args);
}

export default class CiDash extends View {
  init(given, cx) {
    // Read props once, here, and keep them: props() inside a later callback can
    // answer for another copy. Fall back to props() when the argument is empty.
    this.props = (given && Object.keys(given).length ? given : props()) || {};
    const first = this.props.tab;
    this.tab = TABS.includes(first) ? first : "runs";
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.key = null; this.branch = null;
    this.resolving = false;
    this.repo = null; this.gh = null; this.root = null; this.error = null;
    this.dsp = new Dispatch(this);
    this.runFilter = this.makeFilter("Filter runs…");
    this.artFilter = this.makeFilter("Filter artifacts…");
    this.reset();
    cx.timer.every(POLL_MS, (cx) => this.tick(cx));
  }

  makeFilter(placeholder) {
    const state = InputState.new({ placeholder });
    state.on("change", (_e, cx) => cx.notify());
    return state;
  }

  reset() {
    this.runs = []; this.runsLoading = false; this.runsError = null; this.runsLoaded = false;
    this.runKeys = []; // the runs list's entries as drawn: `g-<group>` headings and `r-<run id>` rows
    this.detail = null; this.sel = null;
    this.art = { groups: [], failed: 0, loaded: false, loading: false, error: null };
    this.dl = {}; this.lastDir = ""; this.note = null; // { text, error }
    this.runStatus = "all"; this.artStatus = "all"; this.artType = "all";
    this.runFilter.set_value(""); this.artFilter.set_value("");
    this.dsp.reset();
  }

  /** Props `filter` and `status` pre-fill the filter box and chip of the Runs and Artifacts tabs, once. */
  applyFilterProps() {
    if (this.filterPropsApplied) return;
    this.filterPropsApplied = true;
    const { filter, status, type } = this.props;
    if (filter) { this.runFilter.set_value(String(filter)); this.artFilter.set_value(String(filter)); }
    if (RUN_GROUPS.some((g) => g.id === status)) this.runStatus = status;
    if (ART_GROUPS.some((g) => g.id === status)) this.artStatus = status;
    if (type) this.artType = String(type).toLowerCase().replace(/^\./, "");
  }

  /** The PR's commit as the runs list's scope, and its run opened when it has one; once per request. */
  applySelection(cx) {
    const sel = this.selected;
    if (!sel || sel.applied) return;
    sel.applied = true;
    this.tab = "runs"; this.runStatus = "all";
    this.runFilter.set_value("");
    this.rescope(cx);
    if (sel.runId) this.openRun(Number(sel.runId), cx);
  }

  /** The runs list scoped to a PR's commit (pr-flow's "View in CI"), or null for the repo's latest runs. */
  scope() { return this.selected?.sha ? this.selected : null; }

  /** Reloads the runs list for a new scope, dropping what the old one showed. */
  rescope(cx) {
    this.runs = []; this.runsLoaded = false; this.runsError = null; this.detail = null; this.sel = null;
    this.loadRuns(cx);
  }

  clearScope(cx) {
    if (this.selected) this.selected.sha = null;
    this.rescope(cx);
  }

  /** Loads what a tab needs the first time it is shown. */
  enterTab(cx) {
    if (this.tab === "dispatch") this.dsp.load(cx);
    else if (this.tab === "artifacts" && !this.art.loaded && !this.art.loading) this.loadArtifactTab(cx);
  }

  // ---- repository --------------------------------------------------------

  ensureContext(cx) {
    const { cwd, on, branch } = location();
    const key = `${on ?? ""}|${cwd ?? ""}`;
    // pr-flow's "View in CI" (shared "ci.select"): that PR's repo, its commit's runs, a run to open.
    // The repo and scope hold until focus moves to another folder.
    const sel = shared("ci.select");
    if (sel?.at > (this.selAt ?? Date.now() - 1000) && sel.repo) {
      this.selAt = sel.at;
      this.selected = { ...sel, key };
      if (this.override !== sel.repo) { this.override = sel.repo; this.key = null; }
      else if (this.repo) this.applySelection(cx);
    } else this.selAt ??= Date.now();
    if (this.override && this.selected?.key !== key) {
      const scoped = this.scope();
      this.override = null; this.selected = null; this.key = null;
      if (scoped) this.rescope(cx);
    }
    if (key === this.key) { if (branch) this.branch = branch; return; }
    this.key = key;
    this.branch = branch;
    this.resolve(cx, cwd, on);
  }

  resolve(cx, cwd, on) {
    if (this.resolving) { this.pending = { cwd, on }; return; }
    this.resolving = true;
    const override = this.override ?? this.props.repo;
    cx.spawn(async (cx) => {
      try {
        if (!cwd && !override) throw new Error("No folder to look for a repository in.");
        const repo = await resolveRepo({ cwd, on, override });
        const changed = !this.repo || this.repo.slug !== repo.slug || this.repo.host !== repo.host;
        if (changed) {
          this.repo = repo; this.gh = new Gh({ repo, cwd, on }); this.reset(); this.error = null;
          this.applyFilterProps();
          const top = cwd ? await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null) : null;
          this.root = top && top.code === 0 ? top.stdout.trim() : cwd;
          this.loadRuns(cx);
          this.enterTab(cx);
        } else {
          this.gh.cwd = cwd; this.gh.on = on;
        }
        this.applySelection(cx);
      } catch (e) {
        // The focused folder has no GitHub repository: say so for this folder rather than
        // keep showing the last repository's runs (which read as this tab's CI). A newer
        // context waiting in pending replaces this at once.
        if (!this.pending) {
          this.repo = null; this.gh = null; this.root = null;
          this.reset();
          this.error = e;
        }
      } finally {
        this.resolving = false;
        const next = this.pending; this.pending = null;
        if (next) this.resolve(cx, next.cwd, next.on);
        cx.notify();
      }
    });
  }

  // ---- polling -----------------------------------------------------------

  tick(cx) {
    // Nothing to keep fresh while the panel shows another child or the window is in the background.
    if (!this.gh || !appWindow().active || (this.props.panel && !onScreen())) return;
    if (this.dsp.locate) this.dsp.tryLocate(cx);
    const d = this.detail;
    if (d) {
      const holding = d.hold && Date.now() < d.hold;
      const live = !stateOf(d.run).done || holding;
      // Back off like the TUI: every 5 s at first, then 10 s, then 30 s.
      const due = d.tick <= 12 || (d.tick <= 60 ? d.tick % 2 === 0 : d.tick % 6 === 0);
      if (live && due) this.pollDetail(cx);
      else cx.notify(); // keeps "3m ago" and running durations fresh
      return;
    }
    if (this.tab === "runs" && this.runs.some((r) => !stateOf(r).done)) this.loadRuns(cx, true);
  }

  // ---- runs --------------------------------------------------------------

  loadRuns(cx, silent = false) {
    const gh = this.gh, sha = this.scope()?.sha ?? null;
    if (!gh) return;
    // A load for another scope is in flight: load again for this one when it lands.
    if (this.runsLoading) { if (sha !== this.runsSha) this.runsStale = true; return; }
    this.runsLoading = true; this.runsSha = sha;
    if (!silent) this.runsError = null;
    cx.spawn(async (cx) => {
      try {
        const runs = await gh.listRuns(30, sha);
        if (this.gh !== gh) return;
        if ((this.scope()?.sha ?? null) !== sha) { this.runsStale = true; return; }
        if (this.runsLoaded) {
          const before = new Map(this.runs.map((r) => [r.id, stateOf(r).done]));
          for (const r of runs) if (before.get(r.id) === false && stateOf(r).done) this.announce(r);
        }
        this.runs = runs; this.runsLoaded = true; this.runsError = null;
      } catch (e) {
        if (this.gh === gh && (!silent || !this.runs.length)) this.runsError = e;
      } finally {
        this.runsLoading = false;
        if (this.runsStale) { this.runsStale = false; this.loadRuns(cx); }
        cx.notify();
      }
    });
    cx.notify();
  }

  announce(run) {
    const st = stateOf(run);
    notify({
      title: `CI ${st.label}: ${run.name || "workflow"}`,
      body: `#${run.run_number ?? "?"} · ${run.head_branch || ""} · ${duration(run.run_started_at || run.created_at, run.updated_at)}`,
      level: st.kind === "success" ? "success" : st.kind === "failure" ? "error" : "info",
    });
  }

  openRun(id, cx) {
    this.detail = { id, run: this.runs.find((r) => r.id === id) || null, jobs: [], artifacts: [], artLoaded: false, artError: null, error: null, tick: 0, inFlight: false, live: false, hold: 0, attempt: 0 };
    this.tab = "runs"; this.sel = id;
    this.note = null;
    this.pollDetail(cx);
    cx.notify();
  }

  pollDetail(cx) {
    const d = this.detail, gh = this.gh;
    if (!d || !gh || d.inFlight) return;
    d.inFlight = true;
    cx.spawn(async (cx) => {
      try {
        const [run, jobs] = await Promise.all([gh.getRun(d.id), gh.listJobs(d.id)]);
        if (this.detail !== d) return;
        // Right after a rerun GitHub can still answer with the old attempt.
        const stale = d.hold && Date.now() < d.hold && run.run_attempt === d.attempt;
        d.run = stale ? { ...run, status: "queued", conclusion: null } : run;
        d.jobs = stale ? [] : jobs;
        d.error = null; d.tick += 1;
        const st = stateOf(d.run);
        if (!st.done) d.live = true;
        if (st.done) {
          if (!d.artLoaded) {
            d.artifacts = await gh.listArtifacts(d.id).catch((e) => { d.artError = e; return []; });
            d.artLoaded = true;
          }
          if (d.live) { d.live = false; this.announce(run); }
        }
      } catch (e) {
        if (this.detail === d) d.error = e;
      } finally {
        d.inFlight = false;
        cx.notify();
      }
    });
  }

  act(label, fn, cx) {
    this.note = { text: `${label}…`, error: false };
    cx.notify();
    cx.spawn(async (cx) => {
      try { await fn(); this.note = null; } catch (e) { this.note = { text: `${label} failed: ${e.message || e}`, error: true }; }
      cx.notify();
    });
  }

  cancel(cx) {
    const d = this.detail;
    if (d) this.act("Cancel", async () => { await this.gh.cancelRun(d.id); this.pollDetail(cx); }, cx);
  }

  rerun(cx) {
    const d = this.detail;
    if (!d) return;
    this.act("Rerun", async () => {
      await this.gh.rerunRun(d.id);
      Object.assign(d, { artLoaded: false, artifacts: [], tick: 0, live: false, hold: Date.now() + 20000, attempt: d.run?.run_attempt ?? 0 });
      this.pollDetail(cx);
    }, cx);
  }

  openWeb(cx) {
    const d = this.detail;
    if (d) this.act("Open run", () => this.gh.openRunWeb(d.id), cx);
  }

  // ---- artifacts ---------------------------------------------------------

  loadArtifactTab(cx) {
    const gh = this.gh, art = this.art;
    if (!gh || art.loading) return;
    art.loading = true; art.error = null;
    cx.spawn(async (cx) => {
      let failed = 0, firstError = null;
      try {
        const list = await gh.listWorkflows();
        const workflows = list.filter((w) => w.path?.startsWith(".github/workflows/") && w.state !== "deleted");
        const groups = await mapLimit(workflows, 6, async (workflow) => {
          try {
            for (const run of await gh.latestRuns(workflow.id, 5)) {
              const artifacts = await gh.listArtifacts(run.id);
              if (artifacts.length) return { workflow, run, artifacts };
            }
            return null;
          } catch (e) { failed += 1; firstError = firstError || e; return null; }
        });
        const found = groups.filter(Boolean);
        if (!found.length && firstError) throw firstError;
        const newest = (g) => Math.max(0, ...g.artifacts.map((a) => Date.parse(a.created_at || "") || 0));
        if (this.gh !== gh) return;
        art.groups = found.sort((a, b) => newest(b) - newest(a));
        art.failed = failed; art.loaded = true;
      } catch (e) {
        if (this.gh === gh) art.error = e;
      } finally {
        art.loading = false;
        cx.notify();
      }
    });
    cx.notify();
  }

  download(runId, artifact, cx) {
    const key = `${runId}:${artifact.id}`;
    if (!this.gh || !this.root || this.dl[key]?.state === "busy") return;
    if (artifact.expired) { this.note = { text: `Artifact "${artifact.name}" has expired.`, error: true }; cx.notify(); return; }
    const dir = join(this.root, ".ci-dash", "artifacts", String(runId), safeName(artifact.name));
    const gh = this.gh;
    this.dl[key] = { state: "busy" };
    cx.spawn(async (cx) => {
      try {
        await gh.downloadArtifact(runId, artifact.name, dir);
        this.dl[key] = { state: "done", dir };
        this.lastDir = dir;
      } catch (e) {
        this.dl[key] = { state: "error", msg: String(e.message || e) };
      }
      cx.notify();
    });
    cx.notify();
  }

  openArtifactsFolder(cx) {
    if (!this.root) return;
    const candidates = [this.lastDir, join(this.root, ".ci-dash", "artifacts")].filter(Boolean);
    cx.spawn(async (cx) => {
      for (const dir of candidates) {
        if (await dirExists(dir)) {
          try { await openFolder(dir); this.note = { text: `Opened ${dir}`, error: false }; } catch (e) { this.note = { text: `Could not open ${dir}: ${e}`, error: true }; }
          cx.notify();
          return;
        }
      }
      this.note = { text: `No artifacts downloaded yet. They go to ${candidates[candidates.length - 1]}`, error: false };
      cx.notify();
    });
  }

  // ---- keyboard ----------------------------------------------------------

  /** Reloads what the shown view holds. */
  refresh(cx) {
    if (!this.gh) return;
    if (this.tab === "artifacts") this.loadArtifactTab(cx);
    else if (this.tab === "dispatch") { this.dsp.loaded = false; this.dsp.reset(); this.dsp.load(cx); }
    else if (this.detail) { this.detail.artLoaded = false; this.pollDetail(cx); }
    else this.loadRuns(cx);
  }

  showTab(id, cx) {
    this.tab = id; this.note = null;
    if (id === "runs") this.detail = null;
    this.enterTab(cx);
    cx.notify();
  }

  back(cx) {
    this.detail = null;
    this.reveal(0);
    cx.notify();
  }

  /** Moves the chosen run by `step` rows of the list as drawn. */
  move(step) {
    const rows = this.runKeys.filter((k) => k.startsWith("r-"));
    if (!rows.length) return;
    const at = rows.indexOf(`r-${this.sel}`);
    this.sel = Number(rows[at < 0 ? 0 : Math.max(0, Math.min(rows.length - 1, at + step))].slice(2));
    this.reveal(step);
  }

  /** Scrolls the chosen run into sight; going up onto a group's first run shows its heading too. */
  reveal(step) {
    const at = this.runKeys.indexOf(`r-${this.sel}`);
    if (at >= 0) this.scroll.scroll_to_item(step <= 0 && this.runKeys[at - 1]?.startsWith("g-") ? at - 1 : at);
  }

  onKey(e, cx) {
    // A filter or an input keeps its own keys; Esc hands the keyboard back to the panel.
    if (!this.handle.is_focused()) {
      if (e.key !== "escape") return;
      this.handle.focus();
    } else if (e.keystroke !== e.key) return; // chords belong to the app
    else if (e.key === "escape" || e.key === "backspace") {
      if (this.tab === "runs" && this.detail) this.back(cx);
      else if (this.tab === "dispatch" && this.dsp.step !== "workflows" && !this.dsp.busy) this.dsp.back(cx);
      else if (this.tab !== "runs") this.showTab("runs", cx);
      else return;
    } else if (e.key === "r") this.refresh(cx);
    else if (e.key === "1" || e.key === "2" || e.key === "3") this.showTab(TABS[Number(e.key) - 1], cx);
    else if (this.tab !== "runs" || this.detail) return;
    else if (e.key === "j" || e.key === "down") this.move(1);
    else if (e.key === "k" || e.key === "up") this.move(-1);
    else if (e.key === "enter" && this.runKeys.includes(`r-${this.sel}`)) this.openRun(this.sel, cx);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  // ---- UI pieces ---------------------------------------------------------

  color(kind, t) {
    return { success: t.ansi2, failure: t.ansi1, warning: t.ansi3, running: t.working, queued: t.idle, neutral: t.dim }[kind] ?? t.dim;
  }

  icon(state, t) {
    if (state.kind === "running") return svg(icon("spinner")).size(14).flex_none().text_color(t.working).spin(900);
    return div().w(14).flex_none().text_center().text_size(13).text_color(this.color(state.kind, t)).child(GLYPH[state.kind] ?? "•");
  }

  /** The tinted status word: `passed`, `failed`, `running`… Rows put the status mark beside the title. */
  statePill(state, t) {
    const label = state.label === "success" ? "passed" : state.label;
    return pill(t, { label, color: this.color(state.kind, t) });
  }

  button(id, label, onClick, t, { primary = false, active = false, disabled = false } = {}) {
    return div().id(id).h(26).px(10).flex_none().flex().items_center().rounded(7).text_size(12)
      .border_1().border_color(active || primary ? t.accent : t.border)
      .text_color(disabled ? t.dim : active || primary ? t.accent : t.muted)
      .when(!disabled, (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => onClick(cx)))
      .child(label);
  }

  header(t) {
    // An icon button; without `onClick` it shows dimmed and does nothing.
    const tool = (id, name, tip, onClick) => div().id(id).size(26).flex_none().flex().items_center().justify_center().rounded(6).tooltip(tip)
      .when(Boolean(onClick), (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => onClick(cx)))
      .child(svg(icon(name)).size(14).text_color(onClick ? t.muted : t.dim));
    const tab = (id, label, count) => {
      const active = this.tab === id;
      return h_flex().id(`tab-${id}`).h(24).px(8).gap(6).flex_none().items_center().rounded(6).text_size(12)
        .when(active, (e) => e.bg(t.selected)).text_color(active ? t.foreground : t.muted)
        .cursor_pointer().hover((s) => s.bg(active ? t.selected : t.hover)).tooltip(`${label}  ${TABS.indexOf(id) + 1}`)
        .on_click((_e, cx) => this.showTab(id, cx))
        .child(label)
        .when(count != null, (e) => e.child(div().text_size(11).text_color(t.dim).child(String(count))));
    };
    const artifactCount = this.art.groups.reduce((sum, g) => sum + g.artifacts.length, 0);
    return v_flex().flex_none()
      .child(h_flex().h(42).flex_none().px(12).gap(8).items_center()
        .child(div().flex_none().font_semibold().text_color(t.foreground).child("CI runs"))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.repo ? this.repo.slug : ""))
        .when(this.tab === "artifacts", (e) => e.child(tool("folder", "folder", "Open artifacts folder", this.root ? (cx) => this.openArtifactsFolder(cx) : null)))
        .child(tool("refresh", "refresh", "Refresh  r", this.gh ? (cx) => this.refresh(cx) : null)))
      .child(h_flex().h(32).flex_none().px(10).gap(2).items_center().border_b(1).border_color(t.border)
        .child(tab("runs", "Runs", this.runsLoaded ? this.runs.length : null))
        .child(tab("dispatch", "Dispatch", this.dsp.loaded ? this.dsp.workflows.length : null))
        .child(tab("artifacts", "Artifacts", this.art.loaded ? artifactCount : null))
        .when(this.tab === "runs" && Boolean(this.scope()), (e) => e.child(div().flex_1())
          .child(h_flex().id("scope").h(22).px(8).gap(6).flex_none().items_center().rounded(5).bg(t.selected).text_size(11).text_color(t.muted)
            .cursor_pointer().hover((s) => s.text_color(t.foreground)).tooltip("Show all of the repository's runs")
            .on_click((_e, cx) => this.clearScope(cx))
            .child(`${this.scope().number ? `PR #${this.scope().number} · ` : ""}${this.scope().sha.slice(0, 7)}`)
            .child(svg(icon("close")).size(10).text_color(t.dim)))));
  }

  message(t, title, detail) {
    return v_flex().flex_1().min_h(0).p(16).gap(6).child(div().text_color(t.foreground).child(title)).when(Boolean(detail), (e) => e.child(div().text_size(12).text_color(t.dim).child(detail)));
  }

  errorView(t, error) {
    const text = error?.message || String(error);
    const friendly = friendlyError(text);
    return friendly ? this.message(t, friendly.title, friendly.hint) : this.message(t, text, errorHint(error));
  }

  /** Title and #number on top, then pills: branch, status, duration, trigger. One line each, RUN_ROW_H tall. */
  runRow(r, t) {
    const st = stateOf(r), now = Date.now(), selected = r.id === this.sel;
    const dur = duration(r.run_started_at || r.created_at, st.done ? r.updated_at : now);
    const by = [r.name, r.actor?.login].filter(Boolean).join(" · ");
    return v_flex().id(`run-${r.id}`).w_full().h(RUN_ROW_H).flex_none().px(14).gap(6).justify_center().cursor_pointer()
      .when(selected, (e) => e.bg(t.selected)).hover((s) => s.bg(selected ? t.selected : t.hover))
      .child(h_flex().h(20).gap(10).items_center()
        .child(this.icon(st, t))
        .child(div().flex_1().min_w(0).truncate().child(r.display_title || r.name || `Run ${r.id}`))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(`#${r.run_number}`))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(relTime(r.created_at, now))))
      .child(h_flex().h(20).pl(24).gap(6).items_center().overflow_hidden()
        .when(Boolean(r.head_branch), (e) => e.child(pill(t, { label: r.head_branch, symbol: "branch", code: true }).flex_shrink(1).min_w(0)))
        .child(this.statePill(st, t))
        .when(Boolean(dur), (e) => e.child(pill(t, { label: dur })))
        .when(Boolean(r.event) && r.event !== "push", (e) => e.child(pill(t, { label: r.event.replace(/_/g, " "), color: t.accent })))
        .when((r.run_attempt ?? 1) > 1, (e) => e.child(pill(t, { label: `attempt ${r.run_attempt}` })))
        .when(Boolean(by), (e) => e.child(div().min_w(0).truncate().text_size(11).text_color(t.dim).child(by))));
  }

  clearRunFilters(cx) { this.runFilter.set_value(""); this.runStatus = "all"; cx.notify(); }

  runsView(t) {
    if (this.runsError && !this.runs.length) return this.errorView(t, this.runsError);
    if (!this.runsLoaded) return busy(t, "Loading runs…");
    if (!this.runs.length) {
      if (!this.scope()) return this.message(t, "No workflow runs yet.", "Runs appear here after a workflow executes.");
      return this.message(t, "No GitHub Actions runs for this commit.", "Its checks may come from other systems; the PR panel links to them.")
        .child(h_flex().pt(4).child(this.button("all-runs", "Show all runs", (cx) => this.clearScope(cx), t)));
    }

    const q = this.runFilter.value().trim().toLowerCase();
    const matches = this.runs.filter((r) => !q || [r.display_title, r.name, r.head_branch, r.actor?.login, r.event, `#${r.run_number}`]
      .filter(Boolean).join(" ").toLowerCase().includes(q));
    const count = (id) => matches.filter((r) => groupOf(r) === id).length;
    const shown = this.runStatus === "all" ? matches : matches.filter((r) => groupOf(r) === this.runStatus);

    const chips = [filterChip(t, "rf-all", "All", matches.length, this.runStatus === "all", (cx) => { this.runStatus = "all"; cx.notify(); })];
    for (const g of RUN_GROUPS) {
      if (count(g.id) > 0 || this.runStatus === g.id) {
        chips.push(filterChip(t, `rf-${g.id}`, g.filter, count(g.id), this.runStatus === g.id, (cx) => { this.runStatus = g.id; cx.notify(); }, g.color(t)));
      }
    }

    // Grouped by what to do about them, newest first in each group (the chips above narrow it by state).
    const when = (r) => Date.parse(r.run_started_at || r.created_at) || 0;
    const sorted = [...shown].sort((x, y) => when(y) - when(x) || (y.id ?? 0) - (x.id ?? 0));
    const entries = [];
    for (const g of RUN_GROUPS) {
      const runs = sorted.filter((r) => groupOf(r) === g.id);
      if (!runs.length) continue;
      entries.push({ key: `g-${g.id}`, h: SECTION_H, el: () => section(t, g.label, runs.length, t.muted) });
      for (const r of runs) entries.push({ key: `r-${r.id}`, h: RUN_ROW_H, el: () => this.runRow(r, t) });
    }
    this.runKeys = entries.map((e) => e.key);

    return v_flex().flex_1().min_h(0)
      .child(v_flex().flex_none().px(12).pt(10).pb(2).gap(8)
        .child(searchBox(t, "run-filter", this.runFilter, { right: q || this.runStatus !== "all" ? `${shown.length}/${this.runs.length}` : `${this.runs.length}`, onClear: (cx) => { this.runFilter.set_value(""); cx.notify(); } }))
        .child(h_flex().flex_wrap().gap(4).children(chips)))
      .child(shown.length ? div().flex_1().min_h(0).relative()
        .child(v_virtual_list("runs-rows", entries.length, entries.map((e) => e.h), (i) => entries[i].key,
          (range) => entries.slice(range.start, range.end).map((e) => e.el())).track_scroll(this.scroll).size_full()
          .on_item_click((key, cx) => { if (key.startsWith("r-")) this.openRun(Number(key.slice(2)), cx); }))
        .child(Scrollbar.vertical("runs-rows").viewport_from_layout().absolute().inset_0())
        : v_flex().p(16).gap(8).items_start()
          .child(div().text_size(12).text_color(t.dim).child("No run matches the filters."))
          .child(this.button("clear-run-filters", "Clear filters", (cx) => this.clearRunFilters(cx), t)));
  }

  stepRow(s, t) {
    const st = stateOf(s);
    return h_flex().h(22).flex_none().pl(32).pr(14).gap(8).items_center().text_size(12).text_color(st.done ? t.muted : t.foreground)
      .child(this.icon(st, t))
      .child(div().flex_1().min_w(0).truncate().child(s.name))
      .child(div().flex_none().text_size(11).text_color(t.dim).child(s.started_at && s.completed_at ? duration(s.started_at, s.completed_at) : ""));
  }

  jobBlock(j, t) {
    const st = stateOf(j), now = Date.now();
    return v_flex().flex_none().pb(4)
      .child(h_flex().h(28).flex_none().px(14).gap(8).items_center().font_semibold()
        .child(this.icon(st, t))
        .child(div().flex_1().min_w(0).truncate().child(j.name))
        .child(div().flex_none().text_size(11).text_color(t.muted).child(j.started_at ? duration(j.started_at, j.completed_at ? Date.parse(j.completed_at) : now) : "")))
      .children((j.steps || []).map((s) => this.stepRow(s, t)));
  }

  artifactStatus(runId, a) {
    if (a.expired) return "expired";
    return this.dl[`${runId}:${a.id}`]?.state === "done" ? "downloaded" : "available";
  }

  /** Name and its download action on top, then pills: size, age, and what happened to it. */
  artifactRow(runId, a, t) {
    const key = `${runId}:${a.id}`, dl = this.dl[key];
    const busy = dl?.state === "busy";
    const action = a.expired || busy ? "" : dl?.state === "error" ? "Retry" : dl?.state === "done" ? "Download again" : "Download";
    return v_flex().id(`art-${key}`).w_full().flex_none().px(14).py(8).gap(6)
      .child(h_flex().gap(10).items_center()
        .child(svg(icon("package")).size(14).flex_none().text_color(a.expired ? t.dim : t.accent))
        .child(div().flex_1().min_w(0).truncate().text_color(a.expired ? t.dim : t.foreground).child(a.name))
        .when(Boolean(action), (e) => e.child(div().id(`art-dl-${key}`).h(22).px(6).flex_none().flex().items_center().rounded(5)
          .text_size(12).text_color(t.accent).cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.download(runId, a, cx)).child(action))))
      .child(h_flex().pl(24).flex_wrap().gap(6).items_center()
        .when(Boolean(fileType(a.name)), (e) => e.child(pill(t, { label: `.${fileType(a.name)}`, color: t.accent, code: true })))
        .when(Number.isFinite(a.size_in_bytes), (e) => e.child(pill(t, { label: bytes(a.size_in_bytes) })))
        .when(Boolean(a.created_at), (e) => e.child(pill(t, { label: relTime(a.created_at) })))
        .when(a.expired, (e) => e.child(pill(t, { label: "expired", color: t.ansi1 })))
        .when(dl?.state === "done", (e) => e.child(pill(t, { label: "downloaded", glyph: "✓", color: t.ansi2 })))
        .when(dl?.state === "error", (e) => e.child(pill(t, { label: "failed", glyph: "✕", color: t.ansi1 })))
        .when(busy, (e) => e.child(pill(t, { label: "downloading", spin: true, color: t.working })))
        .when(dl?.state === "done" || dl?.state === "error", (e) => e.child(div().min_w(0).truncate().text_size(11)
          .text_color(dl?.state === "error" ? t.ansi1 : t.dim).child(dl.state === "error" ? dl.msg : dl.dir))));
  }

  detailView(t) {
    const d = this.detail, run = d.run;
    if (!run) return d.error ? this.errorView(t, d.error) : busy(t, "Loading run…");
    const st = stateOf(run), now = Date.now();
    const dur = duration(run.run_started_at || run.created_at, st.done ? run.updated_at : now);
    return v_flex().flex_1().min_h(0)
      .child(h_flex().flex_none().px(12).py(8).gap(8).items_center().border_b(1).border_color(t.border)
        .child(backLink(t, "back", "Runs", (cx) => this.back(cx)))
        .child(div().flex_1())
        .child(this.button("web", "Open", (cx) => this.openWeb(cx), t))
        .when(!st.done, (e) => e.child(this.button("cancel", "Cancel", (cx) => this.cancel(cx), t)))
        .when(st.done, (e) => e.child(this.button("rerun", "Rerun", (cx) => this.rerun(cx), t, { primary: true }))))
      .child(v_flex().id("detail-scroll").flex_1().min_h(0).overflow_y_scrollbar()
        .child(v_flex().flex_none().px(14).py(12).gap(8)
          .child(h_flex().gap(10).items_center().child(this.icon(st, t))
            .child(div().flex_1().min_w(0).truncate().text_size(16).font_semibold().child(run.display_title || run.name))
            .child(div().flex_none().text_size(11).text_color(t.dim).child(`#${run.run_number}`)))
          .child(h_flex().pl(24).flex_wrap().gap(6).items_center()
            .child(this.statePill(st, t))
            .when(Boolean(dur), (e) => e.child(pill(t, { label: dur })))
            .when(Boolean(run.head_branch), (e) => e.child(pill(t, { label: run.head_branch, symbol: "branch", code: true })))
            .when(Boolean(run.event), (e) => e.child(pill(t, { label: run.event.replace(/_/g, " "), color: t.accent })))
            .when((run.run_attempt ?? 1) > 1, (e) => e.child(pill(t, { label: `attempt ${run.run_attempt}` }))))
          .child(div().pl(24).text_size(11).text_color(t.dim).child([run.name, run.actor?.login, relTime(run.created_at, now)].filter(Boolean).join(" · "))))
        .when(d.error, (e) => e.child(div().px(12).pb(6).text_size(11).text_color(t.ansi1).child(`Update failed: ${d.error.message || d.error}`)))
        .children(d.jobs.map((j) => this.jobBlock(j, t)))
        .when(!d.jobs.length && !d.error, (e) => e.child(div().px(12).py(6).text_size(12).text_color(t.dim).child("Waiting for jobs…")))
        .when(st.done && (d.artifacts.length > 0 || d.artError), (e) => e
          .child(section(t, "Artifacts", d.artifacts.length, t.muted))
          .when(Boolean(d.artError), (x) => x.child(div().px(14).text_size(11).text_color(t.ansi1).child(`Could not list artifacts: ${d.artError.message}`)))
          .children(d.artifacts.map((a) => this.artifactRow(run.id, a, t)))));
  }

  artifactsView(t) {
    const art = this.art;
    if (art.error) return this.errorView(t, art.error);
    if (art.loading && !art.loaded) return busy(t, "Loading artifacts…", "Reading the latest runs of every workflow.");
    if (!art.loaded) return busy(t, "Loading artifacts…");
    if (!art.groups.length) return this.message(t, "No artifacts found.", "None of the latest runs of any workflow produced artifacts.");

    const q = this.artFilter.value().trim().toLowerCase();
    const matches = art.groups.flatMap((g) => g.artifacts
      .filter((a) => !q || `${a.name} ${g.workflow.name} ${g.run.head_branch || ""}`.toLowerCase().includes(q))
      .map((a) => ({ g, a, status: this.artifactStatus(g.run.id, a), type: fileType(a.name) || "other" })));
    const total = art.groups.reduce((sum, g) => sum + g.artifacts.length, 0);
    const statusOk = (m) => this.artStatus === "all" || m.status === this.artStatus;
    const typeOk = (m) => this.artType === "all" || m.type === this.artType;
    const shown = matches.filter((m) => statusOk(m) && typeOk(m));

    // Each row of chips counts what the other one already allows, so a number
    // is always what you get by clicking that chip.
    const byStatus = matches.filter(typeOk), byType = matches.filter(statusOk);
    const count = (id) => byStatus.filter((m) => m.status === id).length;
    const chips = [filterChip(t, "af-all", "All", byStatus.length, this.artStatus === "all", (cx) => { this.artStatus = "all"; cx.notify(); })];
    for (const g of ART_GROUPS) {
      if (count(g.id) > 0 || this.artStatus === g.id) {
        chips.push(filterChip(t, `af-${g.id}`, g.filter, count(g.id), this.artStatus === g.id, (cx) => { this.artStatus = g.id; cx.notify(); }, g.color(t)));
      }
    }

    // File types come from the names that are on screen, most common first;
    // names without a known extension are grouped as "other".
    const typeCounts = new Map();
    for (const m of byType) typeCounts.set(m.type, (typeCounts.get(m.type) || 0) + 1);
    if (this.artType !== "all" && !typeCounts.has(this.artType)) typeCounts.set(this.artType, 0);
    const typeIds = [...typeCounts.keys()].sort((a, b) => (a === "other") - (b === "other") || typeCounts.get(b) - typeCounts.get(a) || a.localeCompare(b));
    const hasTypes = art.groups.some((g) => g.artifacts.some((a) => fileType(a.name)));
    const typeChips = hasTypes ? [filterChip(t, "at-all", "All types", byType.length, this.artType === "all", (cx) => { this.artType = "all"; cx.notify(); }),
      ...typeIds.map((id) => filterChip(t, `at-${id}`, id === "other" ? "other" : `.${id}`, typeCounts.get(id), this.artType === id, (cx) => { this.artType = id; cx.notify(); }))] : [];
    const filtering = q || this.artStatus !== "all" || this.artType !== "all";

    const rows = [];
    for (const g of art.groups) {
      const inGroup = shown.filter((m) => m.g === g);
      if (!inGroup.length) continue;
      rows.push(section(t, g.workflow.name, inGroup.length, t.muted, `#${g.run.run_number} · ${g.run.head_branch || ""}`));
      for (const m of inGroup) rows.push(this.artifactRow(g.run.id, m.a, t));
    }

    return v_flex().flex_1().min_h(0)
      .child(v_flex().flex_none().px(12).pt(10).pb(2).gap(8)
        .child(searchBox(t, "art-filter", this.artFilter, { right: filtering ? `${shown.length}/${total}` : `${total}`, onClear: (cx) => { this.artFilter.set_value(""); cx.notify(); } }))
        .child(h_flex().flex_wrap().gap(4).children(chips))
        .when(typeChips.length > 0, (e) => e.child(h_flex().flex_wrap().gap(4).items_center()
          .child(div().px(4).flex_none().text_size(11).text_color(t.dim).child("Type"))
          .children(typeChips))))
      .child(v_flex().id("art-scroll").flex_1().min_h(0).overflow_y_scrollbar().pb(8)
        .when(art.failed > 0, (e) => e.child(div().px(14).pt(8).text_size(11).text_color(t.blocked).child(`${art.failed} workflow(s) could not be read.`)))
        .children(rows)
        .when(!shown.length, (e) => e.child(v_flex().p(16).gap(8).items_start()
          .child(div().text_size(12).text_color(t.dim).child("No artifact matches the filters."))
          .child(this.button("clear-art-filters", "Clear filters", (cx) => { this.artFilter.set_value(""); this.artStatus = "all"; this.artType = "all"; cx.notify(); }, t)))));
  }

  render(cx) {
    this.ensureContext(cx);
    const t = theme();
    let body;
    if (!this.repo) body = this.error ? this.errorView(t, this.error) : this.message(t, "Looking for a GitHub repository…");
    else if (this.tab === "artifacts") body = this.artifactsView(t);
    else if (this.tab === "dispatch") body = this.dsp.view(t);
    else body = this.detail ? this.detailView(t) : this.runsView(t);

    return v_flex().id("ci-dash").size_full().min_h(0).rounded(this.props.panel ? 0 : 10).overflow_hidden().bg(t.background).when(!this.props.panel, (el) => el.border_1().border_color(t.border)).when(Boolean(this.props.panel), (el) => el.border_t(1).border_b(1).border_color(t.border)).text_color(t.foreground).text_size(13)
      .track_focus(this.handle).on_key_down((e, cx) => this.onKey(e, cx)).on_mouse_down("left", () => this.handle.focus())
      .child(this.header(t))
      .child(body)
      .when(Boolean(this.note), (e) => e.child(div().flex_none().px(12).py(6).border_t(1).border_color(t.border).text_size(11).text_color(this.note.error ? t.blocked : t.muted).truncate().child(this.note.text)));
  }
}
