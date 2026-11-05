// The focus sidebar: no spaces, only the agents still asking for attention, as cards, latest news first.
// Below, as in T3: Working (busy agents, folded) and Settled (put away by hand until new work brings them back).
// Settled lives on the agent's own terminal as `settled=<ms>:<turn>`: it ends with the terminal, every mod
// sees it, and a turn ended since says there was new work even while no window watched. Looking doesn't count.
// Settled Claude Code or Pi is also freed at once (by its Settle or by Clear): the agent is exited as a person
// would, the resume command it prints is kept (shared "tui-focus.closed"), and its pane closes. Clicking that
// closed row resumes it in a new tab.
// Reboots: each local Claude Code or Pi terminal is kept by the core and labelled with the line that resumes its
// session (`resume=`) and its terminal's pid (`resume.pid=`). Claude Code's line comes from its own pid file; Pi's
// from integrations/pi.ts, which this mod installs into Pi. A kept terminal comes back from a reboot as a shell
// with a new pid in the same pane: the line is typed into it, or, for a settled one, kept as a closed row.
// Hibernating: an orchestrator worker (a sub-agent labelled `hibernate=ok`) idle past HIBERNATE is exited the same
// way. Its terminal finishes with `hibernated=<ms>` and `resume=<line>` on it, so its parent can revive it (rm,
// then run the line); shared "tui-focus.hibernated" lists them for the cards and the sub-agents popup.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, Scrollbar } from "gpui-base";
import { agents, terminals, panes, spaces, focused, run, openOverlay, hc, exec, notify, theme, shared, setShared, setAgentOrder, props, nextCommand, settings, layout, home, appHome, readTextFile, window } from "herdr";
import { namer } from "./name.js";
import { kidStatus, descendants, treeStatus } from "./tree.js";

const BUSY = new Set(["working", "blocked"]);
// A theme color at some opacity (#rgb or #rrggbb); any other color gives `solid` instead.
function tint(color, alpha, solid) {
  const hex = /^#[0-9a-f]{3}$/i.test(color ?? "") ? "#" + [...color.slice(1)].map((x) => x + x).join("") : color;
  return /^#[0-9a-f]{6}$/i.test(hex ?? "") ? hex + Math.round(alpha * 255).toString(16).padStart(2, "0") : solid;
}
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
// The list's header row (px): the lifted row's copy stays below it and the Pinned label.
const HEAD = 41;
// The settled tail opens on this many, then grows by MORE.
const FIRST = 10, MORE = 25;
// The Settled shelf shows this many rows at most; the rest scroll.
const SETTLED_ROWS = 5;
// A run that stops stays on the Working shelf this long (ms), as in T3: a quick continuation doesn't move it twice.
const GRACE = 2000;
// The last word when times tie, so the order doesn't follow the order the data came in.
const byAddress = (x, y) => x.address.localeCompare(y.address);
// Closed settled agents: [{key, title, space, cwd, program, argv, at}], newest first.
const CLOSED = "tui-focus.closed";
// Hibernated workers: [{address, name, parent, space, cwd, line, at, title, program}], newest first.
const HIBERNATED = "tui-focus.hibernated";
// How each agent exits from its prompt, and the resume line it prints then (both checked by hand: Claude Code
// "Resume this session with: claude --resume <uuid>", Pi "To resume this session: pi --session <id>").
const EXIT = { "claude-code": ["ctrl+c", "ctrl+c"], pi: ["ctrl+d"] };
const RESUME = /claude --resume [0-9a-f-]{36}|pi --session [0-9a-zA-Z-]+/g;
const pause = () => exec("sleep", ["0.3"]).catch(() => null);
// How long an orchestrator worker sits idle before it's hibernated (ms).
const HIBERNATE = 5 * 60000;
// Arriving in Active needing the person (blocked, done), a card glows in its status color, fading natively over
// GLOW (ms): a cue for the corner of the eye, beside Herdr's own sound and toast. A section change reorders at once.
const GLOW = 1200;
// Can be closed and resumed: a local agent that prints a resume line.
const closable = (a) => Boolean(EXIT[a.app]) && !a.address.includes("/");
// How often the resume labels are brought up to date (ms): a reboot loses at most this much of a session switch.
const REMEMBER = 15000;
// Where Pi loads integrations/pi.ts from.
const PI_EXTENSION = ".pi/agent/extensions/herdr-app-session.ts";
// A shell at its prompt, by the foreground process's name (a login shell's starts with "-").
const SHELL = /^-?(zsh|bash|fish|sh|dash|nu)$/;

// As T3's sidebar times: no "ago", nothing past days.
function ago(ms, now) {
  const m = Math.floor((now - ms) / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m`;
  if (m < 1440) return `${Math.floor(m / 60)}h`;
  return `${Math.floor(m / 1440)}d`;
}

// How long it's been working, as T3's Working pill: 9s, 4m, 1h 5m.
function took(ms, now) {
  const s = Math.max(0, Math.floor((now - ms) / 1000)), m = Math.floor(s / 60);
  return s < 60 ? `${s}s` : m < 60 ? `${m}m` : `${Math.floor(m / 60)}h ${m % 60}m`;
}

// The program's icon from the app's table: a one-color glyph or a picture.
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

export default class Focus extends View {
  init(_props, cx) {
    // Each agent's last state, when we saw it set going or come back (ms; 0: before we were watching), the turns
    // it had ended then, and for one that just stopped, when its run started.
    this.changed = JSON.parse(localStorage.getItem("changes") ?? "{}");
    this.open = localStorage.getItem("open") === "true";
    this.workOpen = localStorage.getItem("working-open") === "true";
    this.limit = FIRST;
    // Settled labels written but not back from the core yet: address → value ("" = removed).
    this.pending = {};
    this.hovered = null;
    // Takes the keyboard while a row is lifted, so Esc can put it back.
    this.keys = cx.focus_handle();
    // "Working 9s" counts by the second only while such a card shows under a minute, the window in front; past
    // that it reads in minutes, and the minute tick below moves it on.
    cx.timer.every(1000, (cx) => { if (this.ticking && window()?.active) cx.notify(); });
    // The cards' times (5m, 2h) move on by the minute, as T3's do.
    cx.timer.every(60000, (cx) => cx.notify());
    // One retire per settle (`${address}:${settled}`), so a failure doesn't repeat.
    this.tried = new Set();
    // Reboots: install Pi's half, then label agents and resume recovered shells, now and every REMEMBER.
    cx.spawn(async (cx) => {
      await this.installPi();
      await this.sessions(cx);
    });
    cx.timer.every(REMEMBER, (cx) => this.sessions(cx));
    // `t3-focus.settle` (cmd-shift-s in keys.json): see settleKey in render.
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "settle") this.settleKey?.(cx);
        cx.notify();
      }
    });
  }

  // Takes each agent's state as working, blocked or idle (done counts as idle: looking at it isn't news).
  // A run's place in Working is when it started, as T3's is the person's message: a pause for them, or a stop
  // that goes on within the grace, is the same run. Pinned and settled ones skip the grace, as in T3: their
  // place doesn't hang on it. A turn ended while we weren't watching is news too.
  track(list, all, now, cx) {
    let dirty = false;
    for (const { address, s, turn, excluded } of list) {
      let was = this.changed[address];
      // The grace ran out: back with the person as of then, so it lands on top, and the run is over.
      if (was?.s === "idle" && was.start != null && (excluded || now - was.at >= GRACE)) {
        was = this.changed[address] = { s: "idle", at: excluded ? now : was.at + GRACE, turn: was.turn };
        dirty = true;
      }
      if (was?.s === s && (s !== "idle" || turn <= (was.turn ?? turn))) continue;
      const grace = was?.s === "working" && s === "idle" && !excluded;
      if (grace) cx.timer.after(GRACE, (cx) => cx.notify());
      this.changed[address] = !was ? { s, at: 0, turn } // First sight says nothing about when it changed.
        : s === "working" ? { s, at: was.start ?? now, turn }
        // A pause for the person, stuck: the run keeps its start.
        : s === "blocked" ? { s, at: now, turn, start: was.s === "working" ? was.at : was.start }
        : grace ? { s, at: now, turn, start: was.at } // Stopped: the grace begins.
        : was.start != null && was.s === "idle" ? { ...was, turn } // The turn's end arriving within it.
        : { s, at: now, turn };
      dirty = true;
    }
    if (!dirty) return;
    // Only ended agents lose their record: one missing from the list for a moment comes back to its place.
    const listed = new Set(list.map((a) => a.address));
    const ended = new Set(all.filter((k) => k.state !== "live").map((k) => k.address));
    for (const [k, c] of Object.entries(this.changed)) if (!listed.has(k) && (ended.has(k) || now - c.at > 30 * 86400000)) delete this.changed[k];
    localStorage.setItem("changes", JSON.stringify(this.changed));
  }

  // Shown at once; the label comes back from the core a moment later.
  setSettled(addr, value, cx) {
    this.pending[addr] = value;
    cx.spawn(async (cx) => {
      const r = await hc(["label", addr, `settled=${value}`]).catch((e) => ({ code: 1, stderr: String(e) }));
      if (r.code === 0) return;
      delete this.pending[addr];
      notify({ title: "Couldn't update the agent", body: r.stderr.trim(), level: "error" });
      cx.notify();
    });
  }

  // Frees a settled agent: exits it, keeps the resume line that appears, closes its pane. Local Claude Code and
  // Pi only. When no new resume line shows (a draft in the prompt, a slow exit), it stays settled by label only.

  retire(a, cx) {
    const k = terminals().find((k) => k.address === a.address), once = `${a.address}:${k?.labels?.settled ?? ""}`;
    if (!closable(a) || this.tried.has(once)) return;
    this.tried.add(once);
    const rec = { key: `${a.address}-${Date.now()}`, title: namer()(a), space: a.space, cwd: k?.cwd,
      program: a.program && { name: a.program.name, icon: a.program.icon, tint: a.program.tint } };
    const keys = EXIT[a.app];
    cx.spawn(async (cx) => {
      const read = async () => ((await hc(["read", a.address, "--lines", "80"]).catch(() => null))?.stdout ?? "").match(RESUME) ?? [];
      const before = (await read()).length;
      for (const [i, k] of keys.entries()) {
        if (i) await pause();
        await hc(["keys", a.address, k]).catch(() => null);
      }
      let line = null;
      for (let i = 0; i < 20 && !line; i++) {
        await pause();
        const found = await read();
        if (found.length > before) line = found.at(-1);
      }
      if (!line) {
        notify({ title: "Settled, still running", body: `${rec.title}: no resume command appeared, so it was left open.`, level: "warning" });
        return;
      }
      setShared(CLOSED, [{ ...rec, argv: line.split(" "), at: Date.now() }, ...(shared(CLOSED) ?? [])]);
      await this.closePane(a.pane);
      cx.notify();
    });
  }

  // Check at closure, not before the agent exits: other tabs may have gone meanwhile.
  /** @param {string} pane */
  async closePane(pane) {
    const p = panes().find((p) => p.pane === pane);
    if (!p) return;
    const s = spaces().find((s) => s.tabs.some((t) => t.id === p.tab));
    if (!s) return;
    // Leave the pane open unless its replacement was created.
    if (s.tabs.length === 1 && s.tabs[0].panes === 1 && !(await this.keepSpace(s, p.cwd || s.folder))) return;
    run("pane.close", { pane });
  }

  // A fresh shell tab for a space about to lose its last pane, out of sight: tab.new would select it. A core
  // terminal labelled with a tab id Herdr doesn't know becomes that tab, unselected; no argv runs that machine's
  // shell. True once Herdr lists the tab, so the pane close after it can't take the space.
  async keepSpace(s, folder) {
    const on = s.machine ?? null, local = (id) => id.split("/").pop();
    const tab = `tb${Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join("")}`;
    const args = ["run", "--bg", "--keep", "--no-parent", "--json", "--label", `herdr.space=${local(s.id)}`, "--label", `herdr.tab=${tab}`];
    if (folder) args.push("--cwd", folder);
    if (on) args.push("--on", on);
    const r = await hc(args).catch((e) => ({ code: 1, stderr: String(e) }));
    if (r.code === 0) {
      for (let i = 0; i < 20; i++) {
        if (spaces().find((x) => x.id === s.id)?.tabs.some((t) => local(t.id) === tab)) return true;
        await pause();
      }
    }
    notify({ title: "Couldn't preserve the space", body: r.code === 0 ? "Its new tab didn't appear, so the pane was left open." : r.stderr.trim(), level: "error" });
    return false;
  }

  // Copies integrations/pi.ts into Pi's extensions when it differs (Pi installed only). Pi loads it at start,
  // so a Pi already running reports its session after its next start. mkdir + cp, not `install -D`: BSD install
  // (macOS) reads -D as a destdir.
  async installPi() {
    const pi = `${home()}/.pi/agent`, from = `${appHome()}/mods/tui-focus/integrations/pi.ts`, to = `${home()}/${PI_EXTENSION}`;
    if ((await exec("test", ["-d", pi]).catch(() => null))?.code !== 0) return;
    if ((await exec("cmp", ["-s", from, to]).catch(() => null))?.code === 0) return;
    const fail = (e) => ({ code: 1, stderr: String(e) });
    let r = await exec("mkdir", ["-p", to.slice(0, to.lastIndexOf("/"))]).catch(fail);
    if (r.code === 0) r = await exec("cp", ["-f", from, to]).catch(fail);
    if (r.code !== 0) notify({ title: "Couldn't install the Pi session hook", body: r.stderr.trim(), level: "error" });
  }

  // One pass at a time over every local terminal, sub-agents (no pane of their own) included: a running agent's
  // terminal is labelled, a recovered shell is resumed.
  sessions(cx) {
    if (this.syncing) return;
    this.syncing = true;
    cx.spawn(async (cx) => {
      try {
        for (const t of terminals()) {
          if (t.state !== "live" || t.address.includes("/")) continue;
          const k = await this.inspect(t.address);
          if (!k || k.state !== "live") continue;
          const prompt = SHELL.test(k.foreground?.name ?? "");
          if (!prompt && EXIT[k.status?.app]) {
            await this.remember(k);
            if (this.sleepy(k)) await this.hibernate(k, t);
          } else if (prompt && k.labels?.resume && !k.labels?.hibernated) await this.restore(k);
        }
        // A hibernated worker revived (a new terminal) or removed (reaped) drops its row.
        const kept = [];
        for (const r of shared(HIBERNATED) ?? []) if ((await this.inspect(r.address))?.labels?.hibernated) kept.push(r.address);
        const rows = shared(HIBERNATED) ?? [];
        if (kept.length !== rows.length) setShared(HIBERNATED, rows.filter((r) => kept.includes(r.address)));
      } finally {
        this.syncing = false;
        cx.notify();
      }
    });
  }

  // An orchestrator worker idle (not stuck) past HIBERNATE, once per idle spell. Only its parent works with it, so
  // focus doesn't hold it back as it does a settled agent.
  sleepy(k) {
    return Boolean(k.parent) && k.labels?.hibernate === "ok" && !k.labels?.hibernated && ["idle", "done"].includes(k.status?.state)
      && k.status_ms > 0 && Date.now() - k.status_ms >= HIBERNATE && !this.tried.has(`hibernate:${k.address}:${k.status_ms}`);
  }

  // Exits it as retire() does and keeps its resume line on the finished terminal. Labelled first, so neither
  // this pass nor another window resumes or exits it again meanwhile. Work arriving before a key (its parent
  // sent some) calls it off; no resume line (a draft in its prompt) too, and it keeps running.
  async hibernate(k, t) {
    this.tried.add(`hibernate:${k.address}:${k.status_ms}`);
    const at = Date.now(), wake = () => hc(["label", k.address, "hibernated="]).catch(() => null);
    if ((await hc(["label", k.address, `hibernated=${at}`]).catch(() => null))?.code !== 0) return;
    const read = async () => ((await hc(["read", k.address, "--lines", "80"]).catch(() => null))?.stdout ?? "").match(RESUME) ?? [];
    const before = (await read()).length;
    for (const [i, key] of EXIT[k.status.app].entries()) {
      if (i) await pause();
      const now = await this.inspect(k.address);
      if (now?.state !== "live") break;
      if (!["idle", "done"].includes(now.status?.state)) return void await wake();
      await hc(["keys", k.address, key]).catch(() => null);
    }
    let line = null;
    for (let i = 0; i < 20 && !line; i++) {
      await pause();
      const found = await read();
      if (found.length > before) line = found.at(-1);
    }
    const title = namer()(t);
    if (!line) {
      await wake();
      notify({ title: "Couldn't hibernate", body: `${title}: no resume command appeared, so it was left running.`, level: "warning" });
      return;
    }
    // The worker's browser namespace (start-worker.sh) comes back with it.
    const ns = (k.argv ?? []).find((x) => x.startsWith("AGENT_BROWSER_NAMESPACE="));
    const resume = ns ? `env ${ns} ${line}` : line;
    await hc(["label", k.address, `resume=${resume}`, "resume.pid="]).catch(() => null);
    const program = t.program && { name: t.program.name, icon: t.program.icon, tint: t.program.tint };
    setShared(HIBERNATED, [{ address: k.address, name: k.name, parent: k.parent, space: k.labels?.space, cwd: k.cwd, line: resume, at, title, program },
      ...(shared(HIBERNATED) ?? []).filter((r) => r.address !== k.address)]);
  }

  // The core's full view of a terminal (pid, foreground, labels, keep, status), or null.
  async inspect(address) {
    const r = await hc(["get", address, "--json"]).catch(() => null);
    try {
      return r?.code === 0 ? JSON.parse(r.stdout) : null;
    } catch {
      return null;
    }
  }

  // While an agent runs: its terminal is kept, and labelled with its resume line and its terminal's pid.
  // Claude Code's session id is in ~/.claude/sessions/<its pid>.json, read again every pass. Pi labels
  // itself (integrations/pi.ts); one started before that was installed is read from its own `--session <id>`.
  async remember(k) {
    const labels = k.labels ?? {};
    let line = labels.resume;
    if (k.status.app === "claude-code") {
      const text = await readTextFile(`${home()}/.claude/sessions/${k.foreground?.pid}.json`).catch(() => null);
      let id = null;
      try {
        id = text && JSON.parse(text).sessionId;
      } catch {}
      if (id) line = `claude --resume ${id}`;
    } else if (!line) {
      const at = (k.argv ?? []).indexOf("--session");
      if (at >= 0 && k.argv[at + 1]) line = `pi --session ${k.argv[at + 1]}`;
    }
    if (!line) return;
    if (!k.keep) await hc(["keep", k.address]).catch(() => null);
    const set = [];
    if (line !== labels.resume) set.push(`resume=${line}`);
    if (String(k.pid) !== labels["resume.pid"]) set.push(`resume.pid=${k.pid}`);
    if (set.length) await hc(["label", k.address, ...set]).catch(() => null);
  }

  // A labelled terminal whose shell is at its prompt: the same pid means the agent was quit (forget it); a new
  // pid means the core recovered it after a loss (a reboot). Recovered: the line is typed into its shell, or a
  // settled one becomes a closed row and its pane closes. Labels go first, so no second window sends it again.
  async restore(k) {
    const line = k.labels.resume, was = k.labels["resume.pid"];
    if ((await hc(["label", k.address, "resume=", "resume.pid="]).catch(() => null))?.code !== 0) return;
    // No pid yet (quit before a pass labelled it) or the same pid: quit by hand, not lost.
    if (!was || String(k.pid) === was) return;
    if (k.labels.settled) {
      // The shell's program icon would be wrong here, so the row goes without one.
      setShared(CLOSED, [{ key: `${k.address}-${Date.now()}`, title: k.labels["pi.session"] || k.labels.where || line.split(" ")[0],
        space: k.labels["herdr.space"], cwd: k.cwd, program: null, argv: line.split(" "), at: Date.now() }, ...(shared(CLOSED) ?? [])]);
      const p = panes().find((p) => p.terminal === k.address);
      if (p) await this.closePane(p.pane);
      else await hc(["kill", k.address]).catch(() => null);
      return;
    }
    // ponytail: the line is sent as soon as the shell owns the terminal; zsh keeps typed input until its prompt
    // (direnv included). A shell that drops early input would need a prompt check (`hc read --lines 3`) first.
    const r = await hc(["send", k.address, line]).catch((e) => ({ code: 1, stderr: String(e) }));
    if (r.code !== 0) notify({ title: "Couldn't resume the agent", body: `${k.address}: ${line}\n${r.stderr.trim()}`, level: "error" });
  }

  // Ends a drag or sweep, and hands the keyboard back to the pane that had it, unless the drop moved on to
  // another agent. Not FocusHandle.release(): that frees the handle, and the next drag would throw.
  // `this.back` is set only once something lifted.
  endDrag(restore = true) {
    const back = restore ? this.back : null;
    this.drag = this.sweep = this.back = null;
    if (back?.pane) run("pane.focus", { pane: back.pane });
    else if (back?.terminal) run("pane.focus", { terminal: back.terminal });
    return null;
  }

  render(cx) {
    const t = theme(), now = Date.now();
    const every = agents(), all = terminals(), ps = panes(), sp = spaces();
    const list = every;
    const listed = new Map(every.map((a) => [a.address, a.status]));
    const term = new Map(all.map((k) => [k.address, k]));
    for (const [k, v] of Object.entries(this.pending)) if (!term.has(k) || (term.get(k).labels?.settled ?? "") === v) delete this.pending[k];
    const settledAt = (a) => {
      const v = this.pending[a.address] ?? term.get(a.address)?.labels?.settled;
      return v ? v.split(":").map(Number) : null;
    };
    const kids = new Map(every.map((a) => [a.address, descendants(all, a.address).map((k) => kidStatus(k, listed))]));
    // It, or anything under it, is working or needs the person.
    const busy = (a) => BUSY.has(a.status) || kids.get(a.address).some((s) => BUSY.has(s));
    // New work brings a settled agent back: busy now, or a turn ended since it was settled. Hidden ones too.
    for (const a of every) {
      const s = settledAt(a);
      if (s && (busy(a) || (term.get(a.address)?.turn ?? 0) > s[1])) this.setSettled(a.address, "", cx);
    }
    // It with what's under it (tree.js).
    const state = (a) => treeStatus(a.status, kids.get(a.address));
    const running = (a) => state(a) === "working";
    // Pins are the agents list's (t3-agents), one set for both: pinned agents stay up top in pin order, whatever their state.
    const pins = shared("agents.pins") ?? [];
    this.track(every.map((a) => ({
      address: a.address, s: state(a) === "blocked" ? "blocked" : running(a) ? "working" : "idle",
      turn: term.get(a.address)?.turn ?? 0, excluded: pins.includes(a.address) || Boolean(settledAt(a)),
    })), all, now, cx);
    const mark = (a) => this.changed[a.address];
    // Seen changing, then; before that, the core's time of its last change. terminals() only has that as of
    // the app's start (status_ms isn't updated live), so it serves only until we see a change ourselves.
    const since = (a) => mark(a)?.at || term.get(a.address)?.status_ms || 0;
    // Just stopped: it shows its state now but keeps its Working place until the grace is out.
    const lingering = (a) => mark(a)?.s === "idle" && mark(a).start != null;
    // T3's Working shelf.
    const working = (a) => running(a) || lingering(a);
    // Active by when each came back to the person; Working by when its run started.
    const newest = (x, y) => since(y) - since(x) || byAddress(x, y);
    const begun = (a) => (lingering(a) ? mark(a).start || term.get(a.address)?.status_ms || 0 : since(a));
    // Working since: seen set going; before that, its own report, or for a parent waiting on sub-agents the
    // longest-working one's.
    const started = (a) => mark(a)?.at || (a.status === "working" ? term.get(a.address)?.status_ms
      : Math.min(Infinity, ...descendants(all, a.address).filter((k) => kidStatus(k, listed) === "working").map((k) => k.status_ms).filter(Boolean)));
    const pinned = pins.map((p) => list.find((a) => a.address === p)).filter(Boolean);
    const rest = list.filter((a) => !pins.includes(a.address));
    const out = rest.filter((a) => !settledAt(a) && !working(a)).sort(newest);
    const work = rest.filter((a) => !settledAt(a) && working(a)).sort((x, y) => begun(y) - begun(x) || byAddress(x, y));
    const put = rest.filter(settledAt).sort((x, y) => settledAt(y)[0] - settledAt(x)[0] || byAddress(x, y));
    // Shelves fold by default on this screen; the one in view stays out even folded or past the page, so it's never lost.
    const busyRows = this.workOpen ? work : work.filter((a) => a.focused);
    // Section changes reorder at once. A card arriving in Active needing the person glows: drawn full on the render
    // that sees it arrive, then one render ~50ms later sets its fade's target, and the fade runs natively (shine).
    const sectionNow = new Map([...pinned.map((a) => [a.address, "pinned"]), ...out.map((a) => [a.address, "active"]),
      ...work.map((a) => [a.address, "working"]), ...put.map((a) => [a.address, "settled"])]);
    for (const [k, s] of sectionNow) {
      const was = this.sections?.get(k);
      if (!was || was === s || s !== "active" || this.drag?.moved) continue;
      // Not for the one in view: the person is already looking at it.
      const a = every.find((x) => x.address === k), st = a && state(a);
      if (a.focused || (st !== "blocked" && st !== "done")) continue;
      (this.glows ??= {})[k] = { at: now, color: st === "blocked" ? t.blocked : t.done };
      cx.timer.after(50, (cx) => cx.notify());
    }
    for (const [k, g] of Object.entries(this.glows ?? {})) if (now - g.at > GLOW + 60 || !sectionNow.has(k)) delete this.glows[k];
    this.sections = sectionNow;
    // agent.next goes as the list reads. Only while this list shows: the agents list (t3-agents) sets its own.
    const find = (n) => n?.id === "sidebar-lists" ? n : (n?.children ?? []).map(find).find(Boolean);
    if (find(layout())?.active !== "lists") setAgentOrder([...pinned, ...out, ...work, ...put].map((a) => a.address));

    const title = namer();
    const hover = (a) => (on, cx) => {
      if (on) this.hovered = a.address;
      else if (this.hovered === a.address) this.hovered = null;
      cx.notify();
    };
    // A button's icon and text brighten together: a hover style reaches the text but not the svg, so it's state.
    const glow = (id) => (on, cx) => {
      if (on) this.hot = id;
      else if (this.hot === id) this.hot = null;
      cx.notify();
    };
    const lit = (id, color) => (this.hot === id ? t.foreground : color);
    // A space's avatar, as tui-spaces draws it: the theme's color of that name, the letter in whichever theme
    // text color reads best on it.
    const avatar = (id, name, size) => {
      const color = (shared("space.colors") ?? {})[id] ?? "ansi6", fill = color.startsWith("#") ? color : t[color] ?? t.accent;
      return h_flex().size(size).flex_none().rounded(4).bg(fill)
        .items_center().justify_center().text_size(size * 0.64).font_bold().text_color(ink(t, fill))
        .child([...(name ?? "")][0]?.toUpperCase() ?? "?");
    };
    // Brought back, it's news again: the top of the list. Brought back by the person (`look`), it's also what
    // they look at next; new work bringing it back on its own never moves their focus.
    const unsettle = (a, cx, look = false) => {
      if (look) run("agent.focus", { terminal: a.address });
      this.setSettled(a.address, "", cx);
      this.changed[a.address] = { ...this.changed[a.address], at: Date.now(), start: null };
      localStorage.setItem("changes", JSON.stringify(this.changed));
    };
    // Settling the agent in view moves on to the next card down the list, from the top past the end, as T3 does;
    // one in the background moves nothing.
    const settle = (xs, cx) => {
      // Settling is the person's call: Claude Code and Pi are freed at once, no countdown.
      for (const a of xs) { this.setSettled(a.address, `${Date.now()}:${term.get(a.address)?.turn ?? 0}`, cx); this.retire(a, cx); }
      const cards = [...pinned, ...out, ...busyRows], i = cards.findIndex((a) => a.focused);
      if (i < 0 || !xs.includes(cards[i])) return false;
      const next = [...cards.slice(i + 1), ...cards.slice(0, i)].find((a) => !xs.includes(a));
      if (next) run("agent.focus", { terminal: next.address });
      return Boolean(next);
    };
    // The settle key: the agent in view, as its card's Settle (finished, unpinned) or its settled row's undo.
    this.settleKey = (cx) => {
      const a = every.find((a) => a.focused);
      if (!a) return;
      if (settledAt(a)) unsettle(a, cx);
      else if (!busy(a) && !pins.includes(a.address)) settle([a], cx);
    };

    // Dragging, as T3's sidebar does it (Sidebar.drag.ts, Sidebar.pointer.ts). Press a row and move 6px to lift it;
    // it follows the pointer up and down inside the list and says what letting go will do. While it's lifted, the
    // Pinned and Active labels open, and the list opens a gap the size of the destination's row where it will
    // land. Pinned keeps a hand-made order; Active and Settled keep their own, so the gap opens where that puts it.
    let d = this.drag;
    // A row that leaves the list (its agent ended, a filter) can't be dropped. Render can't run commands, so
    // `this.back` stays and the release (or Esc, or leaving) hands the keyboard back.
    if (d && !list.some((a) => a.address === d.from)) d = this.drag = null;
    const dragging = Boolean(d?.moved);
    const lifted = dragging ? list.find((a) => a.address === d.from) : null;
    const sectionOf = (a) => pins.includes(a.address) ? "pinned" : settledAt(a) ? "settled" : working(a) ? "working" : "active";
    const from = lifted ? sectionOf(lifted) : null;
    const others = (xs) => xs.filter((x) => x.address !== d?.from);
    const pinTo = (before) => ({ section: "pinned", before: before ?? null });
    const pinOrder = (before) => {
      const kept = pins.filter((p) => p !== d.from), at = before ? kept.indexOf(before) : -1;
      kept.splice(at < 0 ? kept.length : at, 0, d.from);
      return kept;
    };
    // What letting go would do, and the gap that shows it: above a row (its address), after a section's last row
    // (`end-…`), right under an empty section's label (`head-…`), or none (a folded or busy destination).
    const plan = (() => {
      const to = lifted && d.target;
      if (!to || (to.section === from && from !== "pinned")) return null;
      if (to.section === "pinned") {
        const order = pinOrder(to.before);
        if (from === "pinned" && order.join("\n") === pins.join("\n")) return null;
        return { section: "pinned", order, gap: to.before ?? (others(pinned).length ? "end-pinned" : "head-pinned") };
      }
      // Busy work can't be settled (new work brings it straight back); out of Pinned it joins the Working shelf.
      if (busy(lifted)) return to.section === "settled" ? null : { section: "active", gap: null };
      if (to.section === "settled") return { section: "settled", gap: !this.open ? null : others(put)[0]?.address ?? "head-settled" };
      const rest = others(out), at = from === "settled" ? 0 : rest.filter((x) => newest(x, lifted) < 0).length;
      return { section: "active", gap: !rest.length ? "head-active" : rest[at]?.address ?? "end-active" };
    })();
    const target = dragging ? d.target?.section ?? null : null;
    // A section lights up as the target, as T3's labels and shelf header do.
    const hot = (s) => target === s && (Boolean(plan) || s === from);
    const verb = !plan ? null : plan.section === "pinned" ? (from === "pinned" ? null : "pin")
      : plan.section === "settled" ? "settle" : from === "pinned" ? "unpin" : from === "settled" ? "unsettle" : null;
    const BADGE = { pin: ["mods/workspace-chrome/pin.svg", "Pin"], unpin: ["mods/workspace-chrome/pin-off.svg", "Unpin"],
      settle: ["mods/workspace-chrome/circle-check.svg", "Settle"], unsettle: ["mods/tui-focus/undo.svg", "Unsettle"] };
    const badge = (v) => h_flex().id(`badge-${v}`).h(20).px(6).gap(4).flex_none().items_center().rounded(4)
      .border(1).border_color(tint(t.accent, 0.4, t.accent)).bg(tint(t.accent, 0.1, t.selected)).text_size(11).font_medium().text_color(t.accent)
      .child(svg(BADGE[v][0]).size(12).flex_none().text_color(t.accent)).child(BADGE[v][1]);

    // Settled shows one page; while a drag moves a row out of it the next row fills in, and one settled into
    // it pushes the page's last row out of sight.
    const fromPage = from === "settled" && put.indexOf(lifted) < this.limit;
    const size = this.limit + (fromPage && plan ? 1 : 0) - (plan?.section === "settled" && from !== "settled" ? 1 : 0);
    const page = this.open ? put.slice(0, size) : [];
    const rows = [...page, ...put.filter((a) => a.focused && !page.includes(a))];

    const aim = (to, cx) => {
      if (!this.drag?.moved || JSON.stringify(this.drag.target ?? null) === JSON.stringify(to)) return;
      this.drag.target = to;
      cx.notify();
    };
    // Over a pin, the upper half drops above it and the lower half below.
    const pinNear = (a, upper) => {
      const xs = pinned.map((x) => x.address), i = xs.indexOf(a.address);
      return pinTo(xs.slice(upper && a.address !== d?.from ? i : i + 1).find((x) => x !== d?.from));
    };
    // The gap: a card and the list's 2px in Pinned and Active, a 30px slim row in Settled (stacked without gaps).
    const MOTION = { duration: 150, easing: "ease-out" };
    const cardH = lifted && from !== "settled" ? d.height : this.cardH ?? 82;
    const gap = (key) => div().id(`gap-${key}`).flex_none().h(plan?.gap !== key ? 0 : plan.section === "settled" ? 30 : cardH + 2)
      .when(dragging, (el) => el.transition("height", MOTION));
    // Each droppable row sits in a lane: the gap that opens above it, the row (folding away once the lifted one is
    // headed elsewhere, holding its place until then) with the list's spacing, and after the last, the end gap.
    const lane = (section, xs, draw, spacing) => xs.map((a, i, ys) => v_flex().id(`lane-${a.address}`).flex_none()
      .child(gap(a.address))
      .child(v_flex().id(`hold-${a.address}`).flex_none()
        .when(dragging && d.from === a.address, (el) => el.overflow_hidden().opacity(0).h(plan ? 0 : d.height + spacing).transition("height", MOTION))
        .child(draw(a)).when(spacing > 0, (el) => el.child(div().h(spacing).flex_none())))
      .when(i === ys.length - 1, (el) => el.child(gap(`end-${section}`))));
    // T3's boundaries: Pinned and Active labels, shown only while dragging; the list opens room for them.
    const boundary = (id, text, section, to) => h_flex().id(id).flex_none().overflow_hidden().h(dragging ? 24 : 0)
      .transition("height", MOTION).px(10).gap(8).items_center().text_size(12).font_medium()
      .on_mouse_move((_e, cx) => aim(to, cx))
      .when(dragging, (el) => el.child(div().text_color(hot(section) ? t.accent : t.muted).child(text))
        .child(div().flex_1().h(1).bg(hot(section) ? tint(t.accent, 0.5, t.accent) : t.border)));
    // An empty section still takes a drop: T3's dashed placeholder, accent while it's the target.
    const placeholder = (section, text) => div().id(`${section}-placeholder`).h(36).mb(2).flex_none().flex().items_center().justify_center()
      .rounded(6).border(1).border_dashed().text_size(12)
      .border_color(hot(section) ? tint(t.accent, 0.4, t.accent) : t.border).text_color(hot(section) ? t.accent : t.muted)
      .when(hot(section), (el) => el.bg(tint(t.accent, 0.05, t.hover)))
      .on_mouse_move((_e, cx) => aim({ section }, cx))
      .child(text);
    // Picked up anywhere on a row that can move (not Working, not one whose Settle is still on its way).
    const row = (el, a) => el
      .on_mouse_down("left", (e) => {
        if (sectionOf(a) === "working" || this.pending[a.address] !== undefined) return;
        this.drag = { from: a.address, at: e.position, grab: e.local_position?.y ?? 0, height: e.bounds?.height ?? 0, moved: false, target: null };
      })
      .on_mouse_move((e, cx) => {
        if (this.sweep?.moved) return sweepTo(a, cx);
        const s = sectionOf(a);
        aim(s === "pinned" ? pinNear(a, (e.local_position?.y ?? 0) < (e.bounds?.height ?? 0) / 2) : s === "working" ? null : { section: s }, cx);
      });
    // A drag's or sweep's release doesn't also click the row or button it ends on.
    const justDropped = () => this.drag?.moved || this.sweep?.moved || Date.now() - (this.dropped ?? 0) < 250;
    const open = (a) => () => {
      if (justDropped()) return;
      run("agent.focus", { terminal: a.address });
    };
    // Says whether it moved on to another agent.
    const drop = (cx) => {
      if (!plan) return false;
      const a = lifted;
      if (plan.section === "pinned") setShared("agents.pins", plan.order);
      else if (pins.includes(a.address)) setShared("agents.pins", pins.filter((p) => p !== a.address));
      if (plan.section === "settled") return settle([a], cx);
      if (!settledAt(a)) return false;
      unsettle(a, cx, true);
      return true;
    };

    // Sweep, T3's other drag: press a card's Settle (or a settled row's undo) and move across rows to take the
    // whole run along; letting go settles (or brings back) every row it marked.
    const sweepFrom = (action, a) => (e, cx) => {
      cx.stop_propagation();
      this.sweep = { action, origin: a.address, at: e.position, moved: false, keys: [a.address] };
    };
    const sweepList = () => this.sweep.action === "settle" ? out.filter((x) => !busy(x)) : rows;
    const sweepTo = (a, cx) => {
      const xs = sweepList().map((x) => x.address), i = xs.indexOf(this.sweep.origin), j = xs.indexOf(a.address);
      if (i < 0 || j < 0) return;
      const keys = xs.slice(Math.min(i, j), Math.max(i, j) + 1);
      if (keys.join("\n") === this.sweep.keys.join("\n")) return;
      this.sweep.keys = keys;
      cx.notify();
    };
    const swept = (a) => Boolean(this.sweep?.moved && this.sweep.keys.includes(a.address));
    const finish = (cx) => {
      if (!this.drag && !this.sweep && !this.back) return;
      const moved = (dragging && drop(cx)) || (Boolean(this.sweep?.moved) && applySweep(cx));
      if (dragging || this.sweep?.moved) this.dropped = Date.now();
      this.endDrag(!moved);
    };
    const applySweep = (cx) => {
      const xs = sweepList().filter((x) => this.sweep.keys.includes(x.address));
      if (this.sweep.action === "settle") return settle(xs, cx);
      // A sweep brings back several: the row it started on is the one to look at.
      for (const a of xs) unsettle(a, cx, a.address === this.sweep.origin);
      return xs.some((a) => a.address === this.sweep.origin);
    };

    // `ghost`: the copy that follows the pointer, drawn without handlers or ids the list already uses.
    const card = (a, ghost) => {
      const st = state(a), on = a.focused;
      const machine = a.address.includes("/") ? a.address.split("/")[0] : null;
      const branch = ps.find((p) => p.pane === a.pane)?.branch;
      const going = kids.get(a.address).filter((s) => s === "working").length;
      // Live sub-agents, finished ones too: with none working, the line still opens the list.
      const live = kids.get(a.address).length + (shared(HIBERNATED) ?? []).filter((r) => r.parent === a.address).length;
      const pic = icon(a.program, 16, t.muted);
      // Hovered, the corner offers Settle, but only for what's finished: a working or stuck tree stays in sight.
      const offer = !dragging && !this.sweep?.moved && this.hovered === a.address && !busy(a) && !pins.includes(a.address);
      const id = `settle-${a.address}`;
      // As in T3, the corner says the state when there's one worth saying (Working, Needs you, Done: finished
      // and not yet seen), else how long ago it last changed. Sized as T3's: 16px mark, 4px gaps, and the
      // time a separate monospace child, so spacing and width don't hang on the interface font.
      const pill = (color, mark, label, time) => h_flex().id(`state-${a.address}`).h(20).gap(4).flex_none().items_center().font_medium().text_color(color)
        .child(mark).child(div().child(label))
        .when(Boolean(time), (el) => el.child(div().font_family(settings().font_family ?? "JetBrains Mono").child(time)));
      // Lifted, or marked by a sweep, the corner says what letting go will do instead.
      const corner = ghost ? (verb ? badge(verb) : div())
        : swept(a) ? badge("settle")
        : offer
        ? h_flex().id(id).h(22).px(6).gap(4).flex_none().items_center().rounded(5)
          .text_size(12).text_color(lit(id, t.muted)).on_hover(glow(id)).cursor_pointer().hover((s) => s.bg(t.hover))
          .role("button").accessibility_label("Settle").tooltip(`Settle  ${window()?.platform === "macos" ? "⌘⇧S" : "Ctrl+Shift+S"}`)
          .on_mouse_down("left", sweepFrom("settle", a))
          .on_click((_e, cx) => {
            cx.stop_propagation();
            if (justDropped()) return;
            // A click is no sweep. Its release stops here, so the sidebar's mouse-up won't end the one the press began.
            this.sweep = null;
            // The card moves away without a pointer-leave event.
            this.hovered = null;
            settle([a], cx);
            cx.notify();
          })
          .child(svg("mods/workspace-chrome/check.svg").size(12).flex_none().text_color(lit(id, t.muted)))
          .child("Settle")
        : running(a)
          ? pill(t.working, svg("mods/workspace-chrome/spinner.svg").size(16).flex_none().text_color(t.working).spin(900),
            "Working", started(a) > 0 && started(a) < Infinity ? took(started(a), now) : null)
            // Waiting on sub-agents with a reply not yet seen: a dot, so the reply isn't lost while it stays here.
            .when(a.status === "done", (el) => el.child(div().id(`reply-${a.address}`).size(6).flex_none().rounded_full().bg(t.done).tooltip("Reply not yet seen")))
          : st === "blocked"
            ? pill(t.blocked, div().size(14).flex_none().rounded(4).bg(tint(t.blocked, 0.15, t.hover)).text_size(11).font_bold().flex().items_center().justify_center().child("!"), "Needs you")
            : st === "done"
              ? pill(t.done, svg("mods/workspace-chrome/circle-check.svg").size(16).flex_none().text_color(t.done), "Done")
              : div().id(`state-${a.address}`).flex_none().child(since(a) > 0 ? ago(since(a), now) : "");
      // Relative only while it glows: its glow is laid over the card's box.
      const base = v_flex().id(`${ghost ? "ghost-" : ""}card-${a.address}`).px(10).py(8).gap(2).flex_none().rounded(10);
      // The arrival glow, drawn under the content: full on the render that sees it arrive, then faded out over GLOW
      // natively once a render sets its target (see sectionNow).
      const g = !ghost && this.glows?.[a.address];
      const shine = g && div().id(`glow-${a.address}`).absolute().top(0).left(0).right(0).bottom(0).rounded(10)
        .bg(tint(g.color, 0.24, t.hover)).opacity(now - g.at < 40 ? 1 : 0).transition("opacity", { duration: GLOW, easing: "ease-out" });
      return (ghost ? base : row(base, a).role("button").accessibility_label(title(a)).on_hover(hover(a)).cursor_pointer()
        // agent.focus, not pane.focus: in tabs it focuses the pane, and it picks what the agent view shows.
        .on_click(open(a)).on_size_change((size) => { this.cardH = size.height; }))
        .when(on, (el) => el.bg(t.selected))
        .when(!on && !ghost && !dragging && !this.sweep?.moved, (el) => el.hover((s) => s.bg(t.hover)))
        .when(Boolean(shine), (el) => el.relative().child(shine))
        .child(h_flex().h(20).gap(6).items_center().text_size(12).text_color(t.dim)
          .child(avatar(a.space, a.space_name, 14))
          // Lifted, a pin keeps its glyph only while it stays among the pins.
          .when(pins.includes(a.address) && (!ghost || plan?.section === "pinned" || !plan), (el) => el.child(svg("mods/workspace-chrome/pin.svg").size(12).flex_none().text_color(t.dim)))
          .child(div().flex_1().min_w(0).truncate().child(machine ? `${a.space_name} · ${machine}` : a.space_name ?? ""))
          .child(corner))
        .child(h_flex().gap(8).items_center()
          // Only the one in view is bright, as in T3.
          .child(div().flex_1().min_w(0).truncate().text_size(13).text_color(on ? t.foreground : t.muted).child(title(a)))
          .when(Boolean(pic), (el) => el.child(pic)))
        // The sub-agents part opens a list of them (tui-subagents); a click there peeks at one.
        .when(Boolean(branch || live), (el) => el.child(h_flex().min_w(0).gap(4).items_center().text_size(12).text_color(t.dim)
          .when(Boolean(branch), (el) => el.child(div().min_w(0).truncate().child(branch)))
          .when(Boolean(branch && live), (el) => el.child(div().flex_none().child("·")))
          .when(Boolean(live) && !ghost, (el) => el.child(div().id(`subs-${a.address}`).flex_none().h(22).px(6).flex().items_center().rounded(5)
            .cursor_pointer().role("button").accessibility_label("Show workers").tooltip(`${live} worker${live > 1 ? "s" : ""}`)
            .hover((s) => s.text_color(t.foreground).bg(t.hover))
            .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
            .on_click((_e, cx) => {
              cx.stop_propagation();
              // Sized for what it will list: the live ones under it and the hibernated ones they or it left.
              const subs = descendants(terminals(), a.address), under = new Set([a.address, ...subs.map((k) => k.address)]);
              const asleep = (shared(HIBERNATED) ?? []).filter((r) => under.has(r.parent)).length;
              openOverlay({ mod: "tui-subagents", kind: "popup", width: 300, height: subsHeight(subs.length, asleep), props: { parent: a.address } });
            })
            .child(going ? `${going} worker${going > 1 ? "s" : ""} working` : "View finished workers")))));
    };

    // A settled row: one dim line; viewing it leaves it settled. Hovered it brightens and its time
    // becomes a bare undo arrow, as in T3.
    const slim = (a, ghost) => {
      const on = a.focused, over = !dragging && !this.sweep?.moved && this.hovered === a.address, bright = on || over || ghost || swept(a);
      const pic = icon(a.program, 14, t.dim);
      const undo = h_flex().id(`unsettle-${a.address}`).size(24).flex_none().items_center().justify_center().rounded(6)
        .on_hover(glow(`unsettle-${a.address}`)).cursor_pointer().hover((s) => s.bg(t.hover))
        .role("button").accessibility_label("Unsettle").tooltip("Unsettle")
        .on_mouse_down("left", sweepFrom("unsettle", a))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          if (justDropped()) return;
          this.sweep = null;
          this.hovered = null;
          unsettle(a, cx, true);
          cx.notify();
        })
        .child(svg("mods/tui-focus/undo.svg").size(14).flex_none().text_color(lit(`unsettle-${a.address}`, t.muted)));
      const base = h_flex().id(`${ghost ? "ghost-" : ""}slim-${a.address}`).h(30).px(10).gap(8).flex_none().items_center().rounded(8);
      return (ghost ? base : row(base, a).role("button").accessibility_label(title(a)).on_hover(hover(a)).on_click(open(a)).cursor_pointer())
        .when(on, (el) => el.bg(t.selected))
        .when(!on && !ghost && !dragging && !this.sweep?.moved, (el) => el.hover((s) => s.bg(t.hover)))
        .child(h_flex().size(16).flex_none().items_center().justify_center().opacity(bright ? 1 : 0.5).when(Boolean(pic), (el) => el.child(pic)))
        .child(div().flex_1().min_w(0).truncate().text_color(bright ? t.foreground : t.muted).child(title(a)))
        .child(ghost ? (verb ? badge(verb) : div()) : swept(a) ? badge("unsettle")
          // No settle time (its label is on its way back from the core): no time on it.
          : over ? undo : div().flex_none().text_size(12).text_color(t.dim).child(!settledAt(a) ? "" : closable(a)
            ? "closing" : ago(settledAt(a)[0], now)));
    };

    // A closed settled agent: the slim row's look; a click resumes it where it was, hovered its time becomes forget.
    const closed = shared(CLOSED) ?? [];
    const forget = (r) => setShared(CLOSED, (shared(CLOSED) ?? []).filter((x) => x.key !== r.key));
    const resume = (r, cx) => cx.spawn(async () => {
      const there = r.cwd && (await exec("test", ["-d", r.cwd]).catch(() => ({ code: 1 }))).code === 0;
      if (!there) {
        notify({ title: "Can't resume", body: `${r.title}: its folder is gone (${r.cwd ?? "unknown"}).`, level: "error" });
        return;
      }
      forget(r);
      // Pi resumes only in its own folder; the space may be gone since.
      if (spaces().some((s) => s.id === r.space)) run("tab.new", { space: r.space, folder: r.cwd, argv: r.argv });
      else run("space.new", { folder: r.cwd, argv: r.argv });
    });
    const closedRow = (r) => {
      const over = !dragging && this.hovered === r.key, id = `forget-${r.key}`;
      return h_flex().id(`closed-${r.key}`).h(30).px(10).gap(8).flex_none().items_center().rounded(8)
        .role("button").accessibility_label(`Resume ${r.title}`).cursor_pointer()
        .when(!dragging, (el) => el.hover((s) => s.bg(t.hover)))
        .on_hover(hover({ address: r.key }))
        .on_click((_e, cx) => { if (!justDropped()) resume(r, cx); })
        .child(h_flex().size(16).flex_none().items_center().justify_center().opacity(over ? 1 : 0.5)
          .when(Boolean(r.program?.icon), (el) => el.child(icon(r.program, 14, t.dim))))
        .child(div().flex_1().min_w(0).truncate().text_color(over ? t.foreground : t.muted).child(r.title))
        .child(over
          ? h_flex().id(id).size(24).flex_none().items_center().justify_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
            .on_hover(glow(id)).role("button").accessibility_label("Forget").tooltip("Forget")
            .on_click((_e, cx) => { cx.stop_propagation(); this.hovered = null; forget(r); cx.notify(); })
            .child(svg("mods/workspace-chrome/x.svg").size(14).flex_none().text_color(lit(id, t.muted)))
          : h_flex().flex_none().gap(4).items_center().text_size(12).text_color(t.dim)
            .child(svg("mods/tui-focus/moon.svg").size(12).flex_none().text_color(t.dim)).child(ago(r.at, now)));
    };

    // A shelf's header, folding it: label, then count and chevron at the far edge.
    const shelf = (id, label, count, open, toggle, extra) => h_flex().id(id).h(30).px(10).gap(6).flex_none().items_center().rounded(8)
      .text_size(12).font_medium().text_color(t.dim).cursor_pointer().when(!dragging, (el) => el.hover((s) => s.bg(t.hover)))
      .role("button").accessibility_label(`${open ? "Hide" : "Show"} ${label.toLowerCase()} agents`)
      .on_click((_e, cx) => {
        toggle();
        cx.notify();
      })
      .child(div().flex_1().child(label))
      .when(Boolean(extra), (el) => el.child(extra))
      .child(div().child(String(count)))
      .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none());

    // Ticks by the second only while a shown working time is still in seconds (took).
    this.ticking = [...pinned, ...busyRows].some((a) => {
      const s = started(a);
      return running(a) && s > 0 && s < Infinity && now - s < 60000;
    });
    // The first shelf takes the free space above it, so both sit at the bottom.
    const shelves = v_flex().id("shelves").pt(12).flex_none()
      .when(work.length > 0, (el) => el
        .child(shelf("working-header", "Working", work.length, this.workOpen, () => {
          this.workOpen = !this.workOpen;
          localStorage.setItem("working-open", String(this.workOpen));
        }).on_mouse_move((_e, cx) => aim(null, cx)))
        .child(v_flex().children(lane("working", busyRows, (a) => card(a), 2))));
    // Clear closes settled agents' panes; Herdr then closes emptied tabs. The one in view stays.
    const spaceNow = sp.find((s) => s.active), tabNow = spaceNow?.tabs.find((c) => c.active)?.id;
    const doomed = put.filter((a) => a.pane && !a.focused && a.tab !== tabNow);
    // With nothing to clear the button goes, and a gone element hears no pointer-leave: drop its ask and hover.
    if (doomed.length === 0) {
      this.clearing = false;
      if (this.hot === "settled-clear") this.hot = null;
    }
    // The ask ends a moment after the pointer leaves the button, or after 3s if the pointer never came (keyboard).
    const unask = (ms, cx) => {
      this.unask?.cancel();
      this.unask = ms > 0 ? cx.timer.after(ms, (cx) => { this.clearing = false; cx.notify(); }) : null;
    };
    const clear = (cx) => {
      if (!this.clearing) {
        this.clearing = true;
        unask(this.hot === "settled-clear" ? 0 : 3000, cx);
        return;
      }
      this.clearing = false;
      unask(0, cx);
      const gone = new Set(doomed.map((a) => a.pane));
      for (const id of new Set(doomed.map((a) => a.space))) {
        const s = sp.find((s) => s.id === id), tabs = s?.tabs.map((c) => c.id) ?? [];
        const mine = ps.filter((p) => tabs.includes(p.tab));
        // Claude Code and Pi skip the countdown but keep their resume command; anything else just closes.
        const close = (cx) => { for (const a of doomed.filter((a) => a.space === id)) closable(a) ? this.retire(a, cx) : run("pane.close", { pane: a.pane }); };
        // The space stays: pane.close refuses its last pane, so a space left empty gets a fresh shell tab first,
        // where its terminals are now: an unnamed space is named after that, and s.folder is only where it began.
        if (mine.every((p) => gone.has(p.pane))) cx.spawn(async (cx) => { if (await this.keepSpace(s, mine.find((p) => p.cwd)?.cwd || s.folder)) close(cx); });
        else close(cx);
      }
    };
    const clearButton = doomed.length > 0 && h_flex().id("settled-clear").h(22).px(6).flex_none().items_center().rounded(5)
      .cursor_pointer().hover((s) => s.bg(t.hover))
      .text_color(this.clearing ? t.blocked : lit("settled-clear", t.dim)).on_hover((on, cx) => {
        if (this.clearing) unask(on ? 0 : 400, cx);
        glow("settled-clear")(on, cx);
      })
      .role("button").accessibility_label(this.clearing ? `Close ${doomed.length} settled agents` : "Clear settled agents")
      .on_click((e, cx) => {
        cx.stop_propagation();
        // A double-click only asks: the second click of it never answers.
        if (this.clearing && e.click_count > 1) return;
        clear(cx);
        cx.notify();
      })
      .child(this.clearing ? `Clear ${doomed.length}?` : "Clear");
    const tail = v_flex().id("settled").flex_none()
      .child(shelf("settled-header", "Settled", put.length + closed.length, this.open, () => {
        this.open = !this.open;
        this.limit = FIRST;
        localStorage.setItem("open", String(this.open));
      }, clearButton).on_mouse_move((_e, cx) => aim({ section: "settled" }, cx))
        // As T3's shelf header: brighter while anything is lifted, accent as the target.
        .when(dragging, (el) => el.text_color(hot("settled") ? t.accent : t.foreground)))
      .when(dragging && others(rows).length === 0 && !(rows.length > 0 && !plan), (el) => el
        .child(plan?.gap === "head-settled" ? gap("head-settled") : placeholder("settled", "Settled")))
      // At most SETTLED_ROWS 30px rows show; the rest scroll, with a bar paired by name (as the shipped worktree list).
      .child(v_flex().relative().flex_none()
      .child(v_flex().id("settled-rows").flex_none().max_h(SETTLED_ROWS * 30).min_h(0).overflow_y_scroll()
      .children(lane("settled", rows, (a) => slim(a), 0))
      .when(this.open, (el) => el.children(closed.map(closedRow)))
      .when(this.open && put.length > this.limit, (el) => el.child(h_flex().id("settled-more").h(30).px(10).gap(8).flex_none().items_center().rounded(8)
        .text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
        .role("button").accessibility_label("Show more settled agents")
        .on_click((_e, cx) => {
          this.limit += MORE;
          cx.notify();
        })
        .child(svg("mods/workspace-chrome/chevron-down.svg").size(12).flex_none())
        .child(`Show ${Math.min(MORE, put.length - this.limit)} more`))))
      .child(Scrollbar.vertical("settled-rows").absolute().inset_0()));

    // The shipped agents list's header in place of T3's search, filter, new space and new agent row.
    const top = h_flex().id("focus-top").px(16).h(HEAD).pt(14).pb(5).flex_none().items_center()
      .child(div().text_size(12).font_medium().text_color(t.dim).child("Agents"));

    return v_flex().id("t3-focus-root").relative().size_full().min_h(0).bg(t.chrome).text_size(13)
      .on_size_change((size) => { this.height = size.height; this.width = size.width; })
      // Esc puts a lifted row back (the sidebar holds the keyboard only while something is lifted).
      .track_focus(this.keys).on_key_down((e, cx) => {
        if (e.keystroke !== "escape" || !(this.drag || this.sweep || this.back)) return;
        this.endDrag();
        cx.notify();
      })
      .on_mouse_move((e, cx) => {
        const g = this.drag ?? this.sweep;
        if (!g || (!g.moved && Math.hypot(e.position.x - g.at.x, e.position.y - g.at.y) <= 6)) return;
        if (!g.moved) { this.back = focused(); this.keys.focus(); }
        g.moved = true;
        g.last = e.local_position ?? g.last;
        if (this.drag) this.drag.y = e.local_position?.y ?? this.drag.y;
        cx.notify();
      })
      // Released anywhere in the sidebar, it lands where the gap shows.
      .on_mouse_up("left", (_e, cx) => { finish(cx); cx.notify(); })
      // Herdr reports no release outside the sidebar, so leaving decides. Off the top or bottom edge (the Pinned
      // label or the Settled shelf sit there) it lands where the badge says, as T3 keeps the last target past the
      // list's ends; off a side it goes back.
      .on_hover((on, cx) => {
        if (on || !(this.drag || this.sweep || this.back)) return;
        const p = (this.drag ?? this.sweep)?.last, w = this.width ?? Infinity, h = this.height ?? Infinity;
        const side = !p || Math.min(p.x, w - p.x) < Math.min(p.y, h - p.y);
        if (side) this.endDrag(); else finish(cx);
        cx.notify();
      })
      .child(top)
      .child(v_flex().id("focus-list").flex_1().min_h(0).px(8).py(8).overflow_y_scroll()
        .child(boundary("pinned", "Pinned", "pinned", pinTo(others(pinned)[0]?.address)))
        .child(gap("head-pinned"))
        .children(lane("pinned", pinned, (a) => card(a), 2))
        .child(boundary("active", "Active", "active", { section: "active" }))
        .when(dragging && others(out).length === 0 && !(out.length > 0 && !plan), (el) => el
          .child(plan?.gap === "head-active" ? gap("head-active") : placeholder("active", "Active")))
        .children(lane("active", out, (a) => card(a), 2))
        .when(out.length === 0 && !dragging, (el) => el.child(div().px(10).py(8).text_size(12).text_color(t.dim)
          .child(every.length ? "Nothing needs you." : "No agent status yet. Agents show up here when they report their status.")))
        // While dragging, Settled shows even empty: it's where a drop settles.
        // The free space above the shelves pushes them to the bottom; a drag over it lands in Active, as T3's
        // nearest-row drop does.
        .child(div().id("active-rest").flex_1().min_h(0).on_mouse_move((_e, cx) => aim({ section: "active" }, cx)))
        .child(shelves.when(put.length > 0 || closed.length > 0 || (dragging && !busy(lifted)), (el) => el.child(tail))))
      // The lifted row moves only up and down, inside the list and below the Pinned label (T3's clamps): the
      // header, the list's 8px top padding, the label's 24px.
      .when(Boolean(lifted) && d.y != null, (el) => el.child(div().id("drag-ghost").absolute().left(8).right(8)
        .top(Math.max(HEAD + 8 + 24, Math.min(d.y - d.grab, (this.height ?? Infinity) - d.height - 8)))
        .rounded(10).bg(t.selected).border(1).border_color(t.accent).shadow_lg()
        .child(from === "settled" ? slim(lifted, true) : card(lifted, true))));
  }
}
