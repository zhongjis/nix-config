import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list, Popover } from "gpui-base";
import { spaces, panes, focused, exec, hc, readTextFile, watchFolder, theme, settings, run, terminals, agents, notify } from "herdr";

/** @typedef {import("gpui-kit").Color} Color */
/** @typedef {import("gpui-kit").Context} Context */
/** @typedef {import("gpui-kit").NativeElement} El */
/** @typedef {import("herdr").AgentInfo} AgentInfo */
/** @typedef {"working" | "staged" | "unpushed" | "pr" | "commit"} Scope */
/** @typedef {{ path: string, status: string, add: number | null, del: number, fresh: boolean, binary: boolean }} FileEntry */
/** @typedef {{ kind: string, number?: number, text: string }} DiffRow */
/** @typedef {{ rows: DiffRow[], more: number } | { note: string }} Mini */
/** @typedef {{ id: string, file: string, line: number | null, body: string }} Note */
/** @typedef {{ address: string, tab: string, pids: number[] }} Hunk */
/** @typedef {Hunk & { notes: Note[] }} Review */
/** @typedef {{ notes: Note[], open: boolean }} Draft */
/** @typedef {{ count: number | null, error: string | null, base: string | null, label: string }} ScopeInfo */
/** @typedef {{ sha: string, short: string, subject: string, when: string }} Commit */
/** @typedef {{ kind: "file", key: string, size: number, file: FileEntry } | { kind: "mini", key: string, size: number, rows: DiffRow[], more: number } | { kind: "more", key: string, size: number, more: number } | { kind: "note", key: string, size: number, text: string }} Item */

/** @type {[Exclude<Scope, "commit">, string][]} */
const SCOPES = [["working", "Working"], ["staged", "Staged"], ["unpushed", "Unpushed"], ["pr", "PR"]];
const MINI_LINES = 10;
const ICON = (/** @type {string} */ name) => `mods/hunk-review/${name}.svg`;

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}
const key = () => JSON.stringify(location());
// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie):
// the folder watch would see it, and every refresh would start the next one.
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
const DIFF = ["--no-ext-diff", "--no-textconv", "--no-color"];
const countLines = (/** @type {string} */ text) => text ? text.split("\n").length - Number(text.endsWith("\n")) : 0;
/** @param {string} path @param {string | null} on @returns {Promise<string | null>} */
async function readText(path, on) {
  try { return await readTextFile(path, { on }); } catch { return null; }
}

/** Theme colors are `#rrggbb[aa]`; parse them once into the type the builders take. */
function palette() {
  /** @type {Record<string, Color>} */
  const out = {};
  for (const [name, value] of Object.entries(theme())) if (isColor(value)) out[name] = value;
  return out;
}
/** @param {string} value @returns {value is Color} */
function isColor(value) { return value.startsWith("#"); }
function monoFont() {
  const family = settings().font_family;
  return typeof family === "string" ? family : "JetBrains Mono";
}

// Numbers each diff line once: new-side numbers, old-side for deletions.
/** @param {string[]} lines @returns {DiffRow[]} */
function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, number: old++, text: line.slice(1) || " " };
    if (kind === "+") return { kind, number: next++, text: line.slice(1) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: line.slice(1) || " " }; }
    return { kind: "", text: line };
  });
}

/** @param {string} out `git diff --numstat -z --no-renames` */
function numstat(out) {
  /** @type {Record<string, { add: number, del: number, binary: boolean }>} */
  const stats = {};
  for (const entry of out.split("\0")) {
    const [a, d, ...parts] = entry.replace(/^\n+/, "").split("\t");
    if (parts.length) stats[parts.join("\t")] = { add: Number(a) || 0, del: Number(d) || 0, binary: a === "-" };
  }
  return stats;
}

/** @param {string} out `git diff --name-status -z --no-renames` */
function nameStatus(out) {
  /** @type {Record<string, string>} */
  const status = {};
  const parts = out.replace(/^\n+/, "").split("\0");
  for (let i = 0; i + 1 < parts.length; i += 2) status[parts[i + 1]] = parts[i].trim()[0] ?? "M";
  return status;
}

// Every live hunk in a Herdr tab, whoever started it: run directly, or in a shell.
// ponytail: local-only. The hunk CLI runs on this computer, so remote spaces list files
// without review; upgrade by running `hunk session list` through exec(..., { on }).
/** @returns {Hunk[]} */
function liveHunks() {
  return terminals()
    .filter((t) => t.state === "live" && t.labels?.["herdr.tab"] && !String(t.address).includes("/")
      && (/(^|\/)hunk$/.test(t.argv?.[0] ?? "") || t.foreground?.name === "hunk"))
    .map((t) => ({ address: String(t.address), tab: String(t.labels["herdr.tab"]), pids: [t.pid, t.foreground?.pid].filter((p) => typeof p === "number") }));
}

/** @param {string} stdout `hunk session list --json` @returns {Map<number, Note[]>} */
function sessionNotes(stdout) {
  /** @type {Map<number, Note[]>} */
  const byPid = new Map();
  const sessions = JSON.parse(stdout).sessions;
  for (const session of Array.isArray(sessions) ? sessions : []) {
    const notes = session.snapshot?.state?.reviewNotes;
    if (typeof session.pid === "number") byPid.set(session.pid, (Array.isArray(notes) ? notes : []).flatMap(userNote));
  }
  return byPid;
}

/** Only the person's notes, not an agent's. @param {any} n JSON from hunk @returns {Note[]} */
function userNote(n) {
  const body = n?.source === "user" && typeof n.body === "string" ? n.body.trim() : "";
  if (!body) return [];
  return [{ id: String(n.noteId), file: String(n.filePath ?? ""), line: typeof n.newRange?.[0] === "number" ? n.newRange[0] : null, body }];
}

/** @param {Note[]} notes */
const message = (notes) => "Address the following code comments in the code:\n\n"
  + notes.map((n) => "- " + n.file + (n.line ? ":" + n.line : "") + " — " + n.body).join("\n");
const plural = (/** @type {number} */ n, /** @type {string} */ word) => `${n} ${word}${n === 1 ? "" : "s"}`;
const STATUS_WORD = { working: "working", blocked: "needs you", done: "done", idle: "idle" };

export default class HunkReview extends View {
  /** @param {import("gpui-shell").Props | undefined} _props @param {import("gpui-kit").AsyncContext} cx */
  init(_props, cx) {
    /** @type {Scope} */ this.scope = "working";
    /** @type {Commit | null} */ this.commit = null;
    /** @type {Commit[]} */ this.commits = [];
    /** @type {FileEntry[]} */ this.files = [];
    /** @type {Partial<Record<Scope, ScopeInfo>>} */ this.scopes = {};
    /** @type {string[] | null} */ this.diffArgs = null;
    /** @type {Set<string>} */ this.expanded = new Set();
    /** @type {Record<string, Mini>} */ this.mini = {};
    /** @type {Record<string, Review>} */ this.reviews = {};
    /** @type {Record<string, Draft>} */ this.drafts = {};
    /** @type {Record<string, string>} */ this.lastAgent = {};
    /** @type {Record<string, string>} */ this.target = {};
    /** @type {string | null} */ this.root = null;
    /** @type {string | null} */ this.on = null;
    /** @type {string | null} */ this.context = null;
    /** @type {string | null} */ this.watched = null;
    /** @type {string | null} */ this.error = null;
    /** @type {string | null} */ this.note = null;
    this.branch = ""; this.loading = false; this.dirty = false; this.hasHead = true; this.limited = false;
    this.sending = false; this.polling = false; this.hitOpen = false;
    /** @type {boolean} */ this.picking = false;
    /** @type {boolean} */ this.choosing = false;
    this.handle = cx.focus_handle();
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
    // hunk drops its notes the instant it quits, so poll fast; tick only runs hunk while one is live.
    cx.timer.every(250, (cx) => this.tick(cx));
  }

  /** @param {string} root @param {Context} cx */
  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched === root) this.refresh(cx);
        }
      } catch { this.watched = null; }
    });
  }

  /** A new repository or scope starts with every diff collapsed. @param {string | null} root */
  reset(root) {
    if (root !== this.root) { this.root = root; this.commit = null; this.commits = []; if (this.scope === "commit") this.scope = "working"; }
    this.files = []; this.expanded.clear(); this.mini = {}; this.diffArgs = null;
  }

  /** @param {Context} cx */
  refresh(cx) {
    if (this.loading) { this.dirty = true; return; }
    const { cwd, on } = location(), context = key();
    if (context !== this.context) { this.context = context; this.error = null; }
    if (!cwd) { this.reset(null); return; }
    const scope = this.scope, commit = this.commit;
    this.loading = true; this.dirty = false;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.reset(null); this.error = "Not a git repository"; return; }
        const root = top.stdout.trim();
        if (root !== this.root || on !== this.on) this.reset(root);
        this.on = on;
        const git = (/** @type {string[]} */ args) => exec("git", [...READ, ...args], { cwd: root, on });
        const [head, branch, upstream, originHead] = await Promise.all([
          git(["rev-parse", "--verify", "--quiet", "HEAD"]),
          git(["rev-parse", "--abbrev-ref", "HEAD"]),
          git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"]),
          git(["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"]),
        ]);
        const hasHead = head.code === 0;
        let main = originHead.code === 0 ? originHead.stdout.trim() : null;
        for (const ref of ["origin/main", "origin/master"]) {
          if (main) break;
          if ((await git(["rev-parse", "--verify", "--quiet", `refs/remotes/${ref}`])).code === 0) main = ref;
        }
        const up = upstream.code === 0 ? upstream.stdout.trim() : main;
        const mergeBase = async (/** @type {string | null} */ ref) => {
          if (!ref || !hasHead) return null;
          const r = await git(["merge-base", "HEAD", ref]);
          return r.code === 0 ? r.stdout.trim() : null;
        };
        const [upBase, prBase] = await Promise.all([mergeBase(up), mergeBase(main)]);
        const failed = (/** @type {string | null} */ ref, /** @type {string} */ missing) => !hasHead ? "No commits yet" : !ref ? missing : "No merge base";
        /** @type {Record<Scope, ScopeInfo>} */
        const info = {
          working: { count: null, error: null, base: null, label: hasHead ? "vs HEAD" : "no commits yet" },
          staged: { count: null, error: null, base: null, label: "index vs HEAD" },
          unpushed: upBase ? { count: null, error: null, base: upBase, label: `vs ${up} · ${upBase.slice(0, 7)}` } : { count: null, error: failed(up, "No upstream"), base: null, label: "" },
          pr: prBase ? { count: null, error: null, base: prBase, label: `vs ${main} · ${prBase.slice(0, 7)}` } : { count: null, error: failed(main, "No origin default branch"), base: null, label: "" },
          commit: commit ? { count: null, error: null, base: commit.sha, label: `${commit.short} ${commit.subject}` } : { count: null, error: "Pick a commit", base: null, label: "" },
        };
        /** @type {Record<Scope, string[] | null>} */
        const args = {
          working: hasHead ? ["diff", "HEAD"] : ["diff", "--cached"],
          staged: ["diff", "--cached"],
          unpushed: upBase ? ["diff", upBase] : null,
          pr: prBase ? ["diff", prBase] : null,
          commit: commit ? ["show", "--format=", commit.sha] : null,
        };
        /** @type {Scope[]} */
        const counted = ["staged", "unpushed", "pr", ...(scope === "commit" ? /** @type {Scope[]} */ (["commit"]) : [])];
        const [status, working, ...others] = await Promise.all([
          git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"]),
          git([...(args.working ?? []), "--numstat", "-z", "--no-renames"]),
          ...counted.map((s) => { const a = args[s]; return a ? git([...a, "--numstat", "-z", "--no-renames"]) : null; }),
        ]);
        if (status.code !== 0) throw new Error(status.stderr.trim());
        const entries = status.stdout.split("\0").filter(Boolean);
        info.working.count = entries.length;
        /** @type {Partial<Record<Scope, ReturnType<typeof numstat>>>} */
        const stats = { working: numstat(working.stdout) };
        counted.forEach((s, i) => {
          const r = others[i];
          if (!r) return;
          if (r.code !== 0) { info[s].error = r.stderr.trim().split("\n")[0] || "git diff failed"; return; }
          stats[s] = numstat(r.stdout);
          info[s].count = Object.keys(stats[s]).length;
        });

        /** @type {FileEntry[]} */
        let files = [];
        if (scope === "working") {
          for (const entry of entries.slice(0, 1000)) {
            const xy = entry.slice(0, 2), path = entry.slice(3), fresh = xy === "??";
            const conflict = xy.includes("U") || xy === "AA" || xy === "DD";
            const s = conflict ? "U" : xy.includes("D") ? "D" : fresh || xy.includes("A") ? "A" : "M";
            const stat = stats.working[path];
            files.push({ path, status: s, fresh, add: stat ? stat.add : fresh ? null : 0, del: stat?.del ?? 0, binary: stat?.binary ?? false });
          }
          // ponytail: untracked files have no numstat, so only the first 50 get line counts;
          // later rows show none and the total undercounts. Upgrade: count on expand.
          await Promise.all(files.filter((f) => f.fresh).slice(0, 50).map(async (f) => {
            const text = await readText(`${root}/${f.path}`, on);
            if (text === null) return;
            if (text.includes("\0")) f.binary = true; else f.add = countLines(text);
          }));
        } else if (args[scope] && stats[scope]) {
          const names = await git([...args[scope], "--name-status", "-z", "--no-renames"]);
          const letters = names.code === 0 ? nameStatus(names.stdout) : {};
          files = Object.entries(stats[scope]).slice(0, 1000).map(([path, s]) => ({ path, status: letters[path] ?? "M", fresh: false, ...s }));
        }
        if (key() !== context || this.root !== root) return;
        this.scopes = info; this.branch = branch.code === 0 ? branch.stdout.trim() : ""; this.hasHead = hasHead; this.error = null;
        if (scope !== this.scope || commit !== this.commit) return;
        this.files = files; this.diffArgs = args[scope]; this.limited = (scope === "working" ? entries.length : Object.keys(stats[scope] ?? {}).length) > 1000;
        this.watch(root, cx);
        for (const path of [...this.expanded]) {
          if (files.some((f) => f.path === path)) await this.loadMini(path);
          else { this.expanded.delete(path); delete this.mini[path]; }
        }
      } catch (e) { if (key() === context) this.error = e instanceof Error ? e.message : String(e); }
      finally {
        this.loading = false; cx.notify();
        if (this.dirty) this.refresh(cx);
      }
    });
  }

  /** The brief view of one file: its first lines in the scope's diff. @param {string} path */
  async loadMini(path) {
    const file = this.files.find((f) => f.path === path), root = this.root, on = this.on, args = this.diffArgs;
    if (!file || !root || !args) return;
    /** @type {Mini} */
    let mini;
    try {
      let lines;
      if (file.fresh) {
        const text = await readText(`${root}/${path}`, on);
        lines = text === null ? null : text.includes("\0") ? ["Binary file"] : [`@@ -0,0 +1,${countLines(text)} @@`, ...text.slice(0, 200000).replace(/\n$/, "").split("\n").map((l) => `+${l}`)];
      } else {
        const r = await exec("git", [...READ, ...args, ...DIFF, "--", path], { cwd: root, on });
        if (r.code !== 0) throw new Error(r.stderr);
        const all = r.stdout.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.startsWith("@@"));
        lines = first < 0 ? [file.binary ? "Binary file" : "No text changes"] : all.slice(first);
      }
      if (!lines) mini = { note: "Cannot read this file" };
      else if (lines.length === 1 && !lines[0].startsWith("@@")) mini = { note: lines[0] };
      else {
        const rows = diffRows(lines);
        mini = { rows: rows.slice(0, MINI_LINES).map((r) => ({ ...r, text: r.text.slice(0, 400) })), more: Math.max(0, rows.length - MINI_LINES) };
      }
    } catch { mini = { note: "Cannot preview this diff" }; }
    if (this.root === root && this.diffArgs === args && this.expanded.has(path)) this.mini[path] = mini;
  }

  /** @param {string} path @param {Context} cx */
  toggle(path, cx) {
    if (this.expanded.delete(path)) { delete this.mini[path]; cx.notify(); return; }
    this.expanded.add(path);
    cx.spawn(async (cx) => { await this.loadMini(path); cx.notify(); });
    cx.notify();
  }

  /** @param {Scope} scope @param {Context} cx */
  setScope(scope, cx) {
    if (scope === this.scope && scope !== "commit") return;
    this.scope = scope; this.files = []; this.expanded.clear(); this.mini = {}; this.diffArgs = null;
    this.refresh(cx); cx.notify();
  }

  /** @param {Context} cx */
  loadCommits(cx) {
    const root = this.root, on = this.on;
    if (!root) return;
    cx.spawn(async (cx) => {
      // ponytail: the picker lists the last 20 commits only. Upgrade: a ref input or paging.
      const r = await exec("git", [...READ, "log", "-20", "--format=%H%x1f%h%x1f%s%x1f%cr"], { cwd: root, on });
      this.commits = r.code !== 0 ? [] : r.stdout.split("\n").filter(Boolean).map((line) => {
        const [sha, short, subject, when] = line.split("\x1f");
        return { sha, short, subject, when };
      });
      cx.notify();
    });
  }

  hunkArgs() {
    const scope = this.scope, base = this.scopes[scope]?.base;
    switch (scope) {
      case "working": return ["diff", "--watch"];
      case "staged": return ["diff", "--staged", "--watch"];
      case "unpushed": case "pr": return base ? ["diff", base, "--watch"] : null;
      case "commit": return this.commit ? ["show", this.commit.sha] : null;
      default: return unreachable(scope);
    }
  }

  /** Opens hunk beside the focused pane, in this tab. @param {string | null} path */
  openHunk(path) {
    const args = this.hunkArgs();
    if (!args || !this.root || this.on) return;
    run("terminal.open", { argv: ["hunk", ...args, ...(path ? ["--", path] : [])], folder: this.root, place: "right" });
  }

  /** Follows every live hunk; keeps its last notes, since hunk forgets them as it quits. @param {import("gpui-kit").AsyncContext} cx */
  tick(cx) {
    const live = liveHunks(), ids = new Set(live.map((h) => h.address));
    let ended = false;
    for (const review of Object.values(this.reviews)) {
      if (ids.has(review.address)) continue;
      delete this.reviews[review.address];
      this.finish(review); ended = true;
    }
    for (const h of live) this.reviews[h.address] ??= { ...h, notes: [] };
    if (ended) cx.notify();
    if (!live.length || this.polling) return;
    this.polling = true;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("hunk", ["session", "list", "--json"]);
        if (r.code !== 0) return;
        const byPid = sessionNotes(r.stdout);
        let changed = false;
        for (const review of Object.values(this.reviews)) {
          const pid = review.pids.find((p) => byPid.has(p));
          const notes = pid === undefined ? null : byPid.get(pid);
          if (!notes || JSON.stringify(notes) === JSON.stringify(review.notes)) continue;
          review.notes = notes; changed = true;
        }
        if (changed) cx.notify();
      } catch {
        // hunk missing or mid-exit: keep the last notes we had.
      } finally { this.polling = false; }
    });
  }

  /** @param {Review} review */
  finish(review) {
    if (!review.notes.length) return;
    const kept = this.drafts[review.tab]?.notes ?? [];
    this.drafts[review.tab] = { notes: [...kept, ...review.notes.filter((n) => !kept.some((k) => k.id === n.id))], open: true };
    if (focused()?.tab !== review.tab) return;
    run("layout.select", { stack: "panel-body", child: "changes" });
    run("layout.show", { id: "panel" });
    this.handle.focus();
  }

  /** @param {string} tab @returns {{ list: AgentInfo[], agent: AgentInfo | null }} */
  targets(tab) {
    const list = agents().filter((a) => a.tab === tab);
    const agent = list.find((a) => a.address === this.target[tab]) ?? list.find((a) => a.address === this.lastAgent[tab]) ?? list[0] ?? null;
    return { list, agent };
  }

  /** @param {string} tab @param {Context} cx */
  send(tab, cx) {
    const draft = this.drafts[tab], { agent } = this.targets(tab);
    if (!draft || !agent || this.sending) return;
    const count = draft.notes.length, text = message(draft.notes), name = agent.program.name;
    this.sending = true; this.note = null;
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["send", agent.address, text]);
        if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim() || `hc send exited ${r.code}`);
        delete this.drafts[tab];
        notify({ title: `Sent ${plural(count, "comment")} to ${name}`, level: "success" });
      } catch (e) { this.note = `Not sent: ${e instanceof Error ? e.message : String(e)}`; }
      finally { this.sending = false; cx.notify(); }
    });
    cx.notify();
  }

  /** @param {string} key @param {Context} cx */
  clickItem(key, cx) {
    const at = key.indexOf(":"), kind = key.slice(0, at), path = key.slice(at + 1), hit = this.hitOpen;
    this.hitOpen = false;
    if (kind === "more" || (kind === "file" && hit)) this.openHunk(path);
    else if (kind === "file") this.toggle(path, cx);
  }

  render(/** @type {Context} */ cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = palette(), mono = monoFont(), tab = focused()?.tab ?? "";
    const seen = agents().find((a) => a.address === focused()?.terminal);
    if (seen) this.lastAgent[seen.tab] = seen.address;
    const live = liveHunks().filter((h) => h.tab === tab), draft = this.drafts[tab];
    const view = live.length ? this.reviewing(live, t, mono) : draft?.open ? this.sheet(tab, draft, t, mono) : this.list(tab, t, mono);
    return v_flex().id("hunk-review").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border)
      .text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (live.length) return;
        if (draft?.open && e.key === "enter") this.send(tab, cx);
        else if (draft?.open && e.key === "escape") { draft.open = false; cx.notify(); }
        else if (!draft?.open && e.key === "enter") this.openHunk(null);
        else return;
        cx.stop_propagation();
      })
      .children(view);
  }

  /** @param {string} title @param {Record<string, Color>} t @param {(El | string)[]} rest */
  header(title, t, rest) {
    return h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().flex_none().font_semibold().child(title)).children(rest);
  }

  /** @param {string} id @param {string} label @param {string | null} hint @param {boolean} enabled @param {Record<string, Color>} t @param {(cx: Context) => void} action */
  primary(id, label, hint, enabled, t, action) {
    return h_flex().id(id).h(30).flex_none().gap(8).items_center().justify_center().rounded(7).text_size(12).font_medium()
      .bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim)
      .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.9)).on_click((_e, cx) => action(cx)))
      .child(label).when(Boolean(hint), (el) => el.child(div().text_size(10).opacity(0.55).child(hint ?? "")));
  }

  /** @param {string} id @param {string} label @param {string | null} hint @param {Color} color @param {Record<string, Color>} t @param {(cx: Context) => void} action */
  ghost(id, label, hint, color, t, action) {
    return h_flex().id(id).flex_1().h(30).gap(8).items_center().justify_center().rounded(7).text_size(12).border_1().border_color(t.input)
      .text_color(color).cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => action(cx))
      .child(label).when(Boolean(hint), (el) => el.child(div().text_size(10).text_color(t.dim).child(hint ?? "")));
  }

  // ── File list ────────────────────────────────────────────────────────────

  /** @param {string} tab @param {Record<string, Color>} t @param {string} mono @returns {El[]} */
  list(tab, t, mono) {
    const scope = this.scope, info = this.scopes[scope], draft = this.drafts[tab];
    const add = this.files.reduce((n, f) => n + (f.add ?? 0), 0), del = this.files.reduce((n, f) => n + f.del, 0);
    const repo = this.root ? this.root.split("/").pop() : "";
    const items = this.items();
    const canOpen = Boolean(this.root && !this.on && this.files.length && this.hunkArgs());
    const empty = this.error ?? info?.error ?? (this.loading || !info ? "Loading changes…" : this.root ? {
      working: "No uncommitted changes", staged: "Nothing staged", unpushed: "Nothing unpushed", pr: "No changes against the base", commit: "No file changes",
    }[scope] : "Focus a terminal in a repository");
    return [
      this.header("Changes", t, [
        div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child([repo, this.branch].filter(Boolean).join(" · ")),
        this.commitPicker(t, mono),
      ]),
      h_flex().mx(10).mt(10).p(2).gap(2).flex_none().rounded(7).bg(t.chrome).border_1().border_color(t.border).children(SCOPES.map(([id, label]) => {
        const on = scope === id, s = this.scopes[id];
        return h_flex().id(`scope-${id}`).flex_1().min_w(0).h(24).gap(4).items_center().justify_center().rounded(5).text_size(12).cursor_pointer()
          .bg(on ? t.raised : t.chrome).text_color(on ? t.foreground : t.muted).when(!on, (el) => el.hover((st) => st.text_color(t.foreground)))
          .when(Boolean(s?.error), (el) => el.tooltip(s?.error ?? ""))
          .on_click((_e, cx) => this.setScope(id, cx))
          .child(div().min_w(0).truncate().child(label))
          .child(div().flex_none().font_family(mono).text_size(10).text_color(t.muted).child(s?.error ? "–" : s?.count === null || s?.count === undefined ? "" : String(s.count)));
      })),
      h_flex().flex_none().px(14).pt(10).pb(4).gap(6).font_family(mono).text_size(11).text_color(t.dim)
        .when(Boolean(info?.error), (el) => el.child(div().text_color(t.blocked).child(info?.error ?? "")))
        .when(Boolean(info && !info.error), (el) => el
          .child(div().min_w(0).truncate().child(info?.label ?? ""))
          .child(div().flex_none().child(`· ${plural(this.files.length, "file")}`))
          .when(add > 0, (e) => e.child(div().flex_none().text_color(t.ansi2).child(`+${add}`)))
          .when(del > 0, (e) => e.child(div().flex_none().text_color(t.ansi1).child(`−${del}`)))),
      items.length
        ? div().id("hr-files-wrap").flex_1().min_h(0).relative().px(6)
          // A list row has no handlers of its own: note where the press landed, so the
          // row's click can tell its ↗ (open hunk at this file) from the row itself.
          .on_mouse_down("left", (e) => { this.hitOpen = Boolean(e.bounds && e.local_position && e.bounds.width - e.local_position.x < 40); })
          .child(v_virtual_list("hr-files", items.length, items.map((i) => i.size), (i) => items[i].key,
            (range) => items.slice(range.start, range.end).map((item) => this.item(item, t, mono)))
            .size_full().on_item_click((k, cx) => this.clickItem(k, cx)))
          .child(Scrollbar.vertical("hr-files").viewport_from_layout().absolute().inset_0())
        : div().flex_1().min_h(0).px(14).py(10).text_size(12).text_color(info?.error ? t.dim : t.muted).child(empty),
      ...(this.limited ? [div().flex_none().px(14).py(4).text_size(11).text_color(t.dim).child("Showing the first 1,000 files")] : []),
      v_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .when(Boolean(draft), (el) => el.child(h_flex().id("hr-draft").h(30).px(10).gap(8).items_center().rounded(7).bg(t.chrome).border_1().border_color(t.border)
          .cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => { if (draft) draft.open = true; this.handle.focus(); cx.notify(); })
          .child(div().size(6).flex_none().rounded(3).bg(t.blocked))
          .child(div().flex_1().min_w(0).truncate().text_size(12).child(`${plural(draft?.notes.length ?? 0, "unsent comment")}`))
          .child(div().flex_none().text_size(12).text_color(t.accent).child("Review"))))
        .when(Boolean(this.on), (el) => el.child(div().text_size(11).text_color(t.dim).child("hunk review works on local spaces only")))
        .child(this.primary("hr-open", "Open in hunk", "↵", canOpen, t, () => this.openHunk(null))),
    ];
  }

  /** @returns {Item[]} */
  items() {
    /** @type {Item[]} */
    const items = [];
    for (const file of this.files) {
      items.push({ kind: "file", key: `file:${file.path}`, size: 28, file });
      if (!this.expanded.has(file.path)) continue;
      const mini = this.mini[file.path];
      if (!mini) items.push({ kind: "note", key: `note:${file.path}`, size: 36, text: "Loading diff…" });
      else if ("note" in mini) items.push({ kind: "note", key: `note:${file.path}`, size: 36, text: mini.note });
      else {
        items.push({ kind: "mini", key: `mini:${file.path}`, size: mini.rows.length * 16 + 12 + (mini.more ? 0 : 7), rows: mini.rows, more: mini.more });
        if (mini.more) items.push({ kind: "more", key: `more:${file.path}`, size: 31, more: mini.more });
      }
    }
    return items;
  }

  /** One virtual-list row: no handlers here, clicks arrive through on_item_click. @param {Item} item @param {Record<string, Color>} t @param {string} mono @returns {El} */
  item(item, t, mono) {
    switch (item.kind) {
      case "file": {
        const f = item.file, parts = f.path.split("/"), name = parts.pop() ?? f.path, open = this.expanded.has(f.path);
        const color = f.status === "A" ? t.ansi2 : f.status === "D" || f.status === "U" ? t.ansi1 : t.ansi3;
        return h_flex().h(28).px(8).gap(7).items_center().rounded(6).cursor_pointer().bg(open ? t.raised : t.background).hover((s) => s.bg(open ? t.raised : t.hover))
          .child(svg(ICON(open ? "chevron-down" : "chevron-right")).size(12).flex_none().text_color(open ? t.foreground : t.dim))
          .child(div().w(10).flex_none().font_family(mono).text_size(11).font_semibold().text_color(color).child(f.status))
          .child(h_flex().flex_1().min_w(0).text_size(12)
            .when(parts.length > 0, (el) => el.child(div().min_w(0).truncate().text_color(t.dim).child(parts.join("/") + "/")))
            .child(div().flex_none().max_w(200).truncate().child(name)))
          .child(h_flex().flex_none().gap(5).font_family(mono).text_size(11)
            .when(f.binary, (el) => el.child(div().text_color(t.dim).child("bin")))
            .when(!f.binary && (f.add ?? 0) > 0, (el) => el.child(div().text_color(t.ansi2).child(`+${f.add}`)))
            .when(!f.binary && f.del > 0, (el) => el.child(div().text_color(t.ansi1).child(`−${f.del}`))))
          .child(div().size(20).flex_none().flex().items_center().justify_center().rounded(4).text_color(t.muted).hover((s) => s.bg(t.hover).text_color(t.accent))
            .child(svg(ICON("open")).size(12)));
      }
      case "mini": {
        const box = div().size_full().py(4).overflow_hidden().bg(t.chrome).border_color(t.border).font_family(mono).text_size(11)
          .when(item.more > 0, (el) => el.border_t(1).border_l(1).border_r(1).rounded_t(5))
          .when(item.more === 0, (el) => el.border_1().rounded(5))
          .children(item.rows.map((row) => row.kind === "@"
            ? div().h(16).px(8).truncate().bg(t.raised).text_color(t.accent).child(row.text)
            : h_flex().h(16).when(row.kind === "+", (el) => el.bg(`${t.ansi2}1c`)).when(row.kind === "-", (el) => el.bg(`${t.ansi1}1c`))
              .child(div().w(30).flex_none().pr(6).text_right().text_color(t.dim).child(row.number === undefined ? "" : String(row.number)))
              .child(div().w(10).flex_none().text_color(row.kind === "+" ? t.ansi2 : row.kind === "-" ? t.ansi1 : t.dim).child(row.kind === "+" || row.kind === "-" ? row.kind : ""))
              .child(div().flex_1().min_w(0).pr(8).truncate().text_color(row.kind ? t.foreground : t.muted).child(row.text))));
        return div().h(item.size).pl(26).pr(8).pt(2).when(item.more === 0, (el) => el.pb(7)).child(box);
      }
      case "more":
        return div().h(item.size).pl(26).pr(8).pb(7).cursor_pointer().child(h_flex().size_full().px(8).gap(4).items_center().bg(t.chrome)
          .border_l(1).border_r(1).border_b(1).border_color(t.border).rounded_b(5).text_size(11).text_color(t.muted).hover((s) => s.bg(t.hover))
          .child(`${plural(item.more, "more line")} ·`).child(div().text_color(t.accent).child("open in hunk")));
      case "note":
        return div().h(item.size).pl(26).pr(8).pt(2).pb(7).child(div().size_full().px(8).flex().items_center().rounded(5).bg(t.chrome).border_1().border_color(t.border)
          .text_size(11).text_color(t.dim).child(item.text));
      default: return unreachable(item);
    }
  }

  /** @param {Record<string, Color>} t @param {string} mono */
  commitPicker(t, mono) {
    const on = this.scope === "commit" && this.commit;
    const trigger = h_flex().id("hr-commit").h(24).flex_none().px(7).gap(5).items_center().rounded(6).cursor_pointer().text_size(12)
      .bg(on ? t.raised : t.background).text_color(on ? t.foreground : t.muted).border_1().border_color(on ? t.border : t.background)
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .child(svg(ICON("commit")).size(13).flex_none())
      .child(on && this.commit ? div().font_family(mono).text_size(11).child(this.commit.short) : div().child("Commit"))
      .child(svg(ICON("chevron-down")).size(11).flex_none().text_color(t.dim));
    const rows = this.commits.map((c) => h_flex().id(`hr-commit-${c.sha}`).h(28).px(8).gap(8).items_center().rounded(5).cursor_pointer()
      .when(this.commit?.sha === c.sha && this.scope === "commit", (el) => el.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { this.picking = false; this.commit = c; this.setScope("commit", cx); })
      .child(div().flex_none().font_family(mono).text_size(11).text_color(t.accent).child(c.short))
      .child(div().flex_1().min_w(0).truncate().text_size(12).child(c.subject))
      .child(div().flex_none().text_size(11).text_color(t.dim).child(c.when.replace(/ ago$/, ""))));
    return Popover.new("hr-commit-picker").anchor("top_right").open(this.picking)
      .on_open_change((open, cx) => { this.picking = open; if (open) this.loadCommits(cx); cx.notify(); })
      .trigger(trigger)
      .content(v_flex().id("hr-commit-list").w(320).max_h(340).overflow_y_scrollbar().p(4).gap(1).rounded(8).bg(t.popover).border_1().border_color(t.border).shadow_lg()
        .text_color(t.foreground)
        .when(!rows.length, (el) => el.child(div().px(8).py(6).text_size(12).text_color(t.dim).child(this.root ? "Loading commits…" : "No repository")))
        .children(rows));
  }

  // ── Reviewing ────────────────────────────────────────────────────────────

  /** @param {Hunk[]} live @param {Record<string, Color>} t @param {string} mono @returns {El[]} */
  reviewing(live, t, mono) {
    const notes = live.flatMap((h) => this.reviews[h.address]?.notes ?? []);
    const { agent } = this.targets(live[0].tab);
    return [
      this.header("Reviewing", t, [div().flex_1(), div().text_size(12).text_color(t.dim).child("hunk open")]),
      h_flex().flex_none().px(14).pt(10).pb(8).gap(8).items_center().text_size(12)
        .child(div().size(7).flex_none().rounded(4).bg(t.ansi2).loop("opacity", { from: 0.35, to: 1, period: 1600 }))
        .child(notes.length ? `${plural(notes.length, "comment")} so far` : "No comments yet"),
      notes.length
        ? v_flex().id("hr-notes").flex_1().min_h(0).overflow_y_scrollbar().px(10).pb(8).gap(6).children(notes.map((n) =>
          v_flex().flex_none().px(10).py(7).gap(2).rounded(7).bg(t.chrome).border_1().border_color(t.border)
            .child(div().truncate().font_family(mono).text_size(11).text_color(t.muted).child(n.file + (n.line ? `:${n.line}` : "")))
            .child(div().text_size(12).child(n.body))))
        : div().flex_1().min_h(0).px(14).text_size(12).text_color(t.dim).child("In hunk, press c on a line, write, then Ctrl+S."),
      v_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(div().text_size(11).text_color(t.dim).text_center().child(`Quit hunk (q) to send to ${agent?.program.name ?? "the agent"}`))
        .child(h_flex().child(this.ghost("hr-focus", "Focus hunk", null, t.foreground, t, () => run("pane.focus", { terminal: live[0].address })))),
    ];
  }

  // ── Confirm sheet ────────────────────────────────────────────────────────

  /** @param {string} tab @param {Draft} draft @param {Record<string, Color>} t @param {string} mono @returns {El[]} */
  sheet(tab, draft, t, mono) {
    const { list, agent } = this.targets(tab), count = draft.notes.length, text = message(draft.notes);
    const name = agent?.program.name ?? "agent";
    const statusColor = (/** @type {AgentInfo} */ a) => t[a.status] ?? t.dim;
    const agentRow = (/** @type {AgentInfo} */ a) => h_flex().flex_1().min_w(0).gap(7).items_center()
      .when(Boolean(a.program.icon), (el) => el.child(a.program.tint ? svg(a.program.icon ?? "").size(14).flex_none().text_color(t.muted) : image(a.program.icon ?? "").size(14).flex_none()))
      .child(div().flex_none().child(a.program.name))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(a.title))
      .child(h_flex().flex_none().gap(5).items_center().font_family(mono).text_size(11).text_color(statusColor(a))
        .child(div().size(6).rounded(3).bg(statusColor(a)).when(a.status === "working", (el) => el.loop("opacity", { from: 0.35, to: 1, period: 1200 })))
        .child(STATUS_WORD[a.status]));
    const target = agent
      ? h_flex().id("hr-target").h(34).px(9).gap(7).items_center().rounded(7).border_1().border_color(t.accent).text_size(12)
        .when(list.length > 1, (el) => el.cursor_pointer().hover((s) => s.bg(t.hover)))
        .child(agentRow(agent))
        .when(list.length > 1, (el) => el.child(svg(ICON("chevron-down")).size(12).flex_none().text_color(t.dim)))
      : h_flex().h(34).px(9).items_center().rounded(7).border_1().border_color(t.border).text_size(12).text_color(t.dim).child("No agent in this tab");
    const picker = list.length > 1
      ? Popover.new("hr-agent-picker").anchor("top_left").open(this.choosing)
        .on_open_change((open, cx) => { this.choosing = open; cx.notify(); })
        .trigger(target)
        .content(v_flex().id("hr-agent-list").w(320).p(4).gap(1).rounded(8).bg(t.popover).border_1().border_color(t.border).shadow_lg().text_color(t.foreground).text_size(12)
          .children(list.map((a) => h_flex().id(`hr-agent-${a.address}`).h(30).px(8).items_center().rounded(5).cursor_pointer()
            .when(a.address === agent?.address, (el) => el.bg(t.selected)).hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => { this.target[tab] = a.address; this.choosing = false; cx.notify(); })
            .child(agentRow(a)))))
      : target;
    return [
      this.header(`Send ${plural(count, "comment")}?`, t, []),
      v_flex().flex_1().min_h(0).p(12).gap(10)
        .child(picker)
        .when(agent?.status === "working", (el) => el.child(div().text_size(11).text_color(t.working).child(`${name} is working: sending steers the current run.`)))
        .child(v_flex().id("hr-preview").flex_1().min_h(0).overflow_y_scrollbar().p(10).gap(2).rounded(7).bg(t.chrome).border_1().border_color(t.border)
          .font_family(mono).text_size(11).text_color(t.foreground)
          .children(text.split("\n").map((line, i) => div().flex_none().when(i === 0, (el) => el.text_color(t.muted)).child(line || " "))))
        .when(Boolean(this.note), (el) => el.child(div().text_size(11).text_color(t.ansi1).child(this.note ?? ""))),
      v_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(this.primary("hr-send", this.sending ? "Sending…" : `Send to ${name}`, this.sending ? null : "↵", Boolean(agent) && !this.sending, t, (cx) => this.send(tab, cx)))
        .when(!agent, (el) => el.child(div().text_size(11).text_color(t.dim).text_center().child("Start an agent in this tab to send")))
        .child(h_flex().gap(8)
          .child(this.ghost("hr-keep", "Keep draft", "esc", t.foreground, t, (cx) => { draft.open = false; cx.notify(); }))
          .child(this.ghost("hr-discard", "Discard", null, t.muted, t, (cx) => { delete this.drafts[tab]; this.note = null; cx.notify(); }))),
    ];
  }
}

/** @param {never} value @returns {never} */
function unreachable(value) { throw new Error(`unexpected ${JSON.stringify(value)}`); }
