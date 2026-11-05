// PR Flow: this repo's open PRs from tui-spaces. A side panel with a list; a PR opens
// in the same panel. It only reads: nothing here writes to GitHub or sends to an agent.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, TextView, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { panes, spaces, focused, exec, run, theme, props, settings, shared, setShared, nextCommand, layout, window as appWindow } from "herdr";
import { createGh, parseRemote, runIdFromUrl } from "./gh.js";
import { createTracker } from "./tracker.js";
import { translator, relative, effectiveLang } from "./i18n.js";
import { facts, statusRows, conversation, descPreview, logTail, flowLine, flowRows, jobSteps, issueState, issueLabel, orderCards } from "./present.js";
import { parseDiff } from "./diff.js";
import { sanitize } from "./text.js";
import { issueRefs } from "./issue-refs.js";

const MOD = "pr-flow";
const VIEW_KEY = "pr-flow.view";
const LANG_KEY = "pr-flow.lang";
const TICK_MS = 5000;
const LANGS = ["auto", "ko", "en"];
// A list row's fixed lines, so the virtual list knows each row's height.
const ROW_PAD = 10, TITLE_H = 22, LINE_H = 20, LINE_GAP = 5;

const icon = (name, size, color) => svg(`mods/${MOD}/${name}.svg`).size(size).flex_none().text_color(color);
// A translucent theme color; a theme color that isn't #rrggbb gets `solid` instead.
const tint = (color, alpha, solid) => (/^#[0-9a-f]{6}$/i.test(color ?? "") ? color + alpha : solid);
const toneColor = (t, tone) => ({ ok: t.ansi2, bad: t.ansi1, warn: t.blocked, wait: t.foreground, run: t.working, merge: t.ansi2, merged: t.ansi5, dim: t.dim, comment: t.muted, todo: t.dim }[tone] ?? t.muted);
const mono = () => settings().font_family ?? "JetBrains Mono";

function factIcon(tone, t) {
  const c = toneColor(t, tone);
  if (tone === "ok") return icon("check", 12, c);
  if (tone === "bad") return icon("cross", 12, c);
  if (tone === "run") return icon("spinner", 11, c).spin(900);
  if (tone === "comment" || tone === "warn") return icon("comment", 12, c);
  if (tone === "merge" || tone === "merged") return icon("merge", 12, c);
  return icon("pending", 10, c);
}
const fact = (f, t) => h_flex().flex_none().gap(4).items_center().child(factIcon(f.tone, t))
  .child(div().text_size(12).text_color(f.tone === "ok" || f.tone === "comment" ? t.muted : toneColor(t, f.tone)).child(f.label));

// Herdr's own agent marks: a spinner working, "!" needing input, a dot done, a ring idle.
function agentMark(status, t) {
  if (status === "working") return icon("spinner", 11, t.working).spin(900);
  if (status === "blocked") return h_flex().size(14).rounded(4).items_center().justify_center().bg(tint(t.blocked, "26", t.hover)).text_size(11).font_bold().text_color(t.blocked).child("!");
  if (status === "done") return div().size(7).rounded(99).bg(t.done);
  return div().size(7).rounded(99).border(1.5).border_color(status === "idle" ? t.idle : t.unknown);
}

// Where the layout shows this mod: false while a hidden node or a stack's other child covers it; null when it isn't there.
/** @returns {boolean | null} */
function shownIn(node) {
  if (node?.content?.mod === MOD) return !node.hidden;
  for (const child of node?.children ?? []) {
    const shown = shownIn(child);
    if (shown !== null) return shown && !node.hidden && (node.type !== "stack" || (node.active ?? node.children[0]?.id) === child.id);
  }
  return null;
}

// The status list's field column; values line up after it.
const FIELD_W = 72;
const valueColor = (t, tone) => ({ bad: t.ansi1, warn: t.blocked, todo: t.dim, dim: t.dim }[tone] ?? t.foreground);
const PR_STATE_TONE = { open: "ok", draft: "dim", merged: "merged", closed: "bad" };

function fileLine(path) {
  const parts = String(path).split("/"), name = parts.pop();
  return { dir: parts.length ? parts.join("/") + "/" : "", name };
}

function openExternal(url) {
  const platform = appWindow()?.platform;
  const [cmd, args] = platform === "macos" ? ["open", [url]] : platform === "windows" ? ["explorer.exe", [url]] : ["xdg-open", [url]];
  exec(cmd, args).catch(() => {});
}

// An app started from the Finder has no LANG, so ask macOS too.
const LOCALE = 'l="${LC_ALL:-${LC_MESSAGES:-$LANG}}"; case "$l" in ""|C|C.*|POSIX) l=$(defaults read -g AppleLocale 2>/dev/null);; esac; printf %s "$l"';
const systemLang = () => exec("sh", ["-c", LOCALE]).then((r) => (/^ko/i.test(r.stdout) ? "ko" : "en")).catch(() => "en");

export default class PrFlow extends View {
  init(_props, cx) {
    const p = props() ?? {};
    this.viewer = p.screen === "viewer";
    this.system = localStorage.getItem("lang") ?? "en";
    this.useLang();
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      const system = await systemLang();
      if (system !== this.system) { this.system = system; localStorage.setItem("lang", system); cx.notify(); }
    });
    if (this.viewer) { this.loaded = null; this.file = 0; return; }

    this.gh = createGh(exec);
    this.scroll = VirtualListScrollHandle.new();
    this.tracker = createTracker({ gh: this.gh });
    this.remotes = new Map();
    this.repo = null;
    this.scopeKey = null;
    this.selection = null;
    this.tracker.sync(shared("tui-spaces.prs"));
    this.url = null; // the open PR; null shows the list
    this.selected = 0;
    this.logs = new Map(); // run id -> { name, runId, repo, tail, full, failed }
    this.opened = new Set(); // timeline rows showing their steps or checks
    this.issueUrl = null; // the issue open in the panel
    this.issueData = new Map(); // url -> issue, or { failed: true }
    this.ghReady = true;
    this.busy = false;
    this.stale = false; // a tick was skipped while hidden: the next render catches up
    this.syncScope(cx);
    this.tick(cx);
    cx.timer.every(TICK_MS, (cx) => this.tick(cx));
    cx.timer.every(60_000, (cx) => cx.notify()); // "5분 전" moves on
    cx.spawn(async (cx) => {
      this.ghReady = await this.gh.authOk().catch(() => false);
      cx.notify();
    });
    // "pr-flow.next" and friends, for keys.json and the command line.
    cx.spawn(async (cx) => {
      for (;;) { const c = await nextCommand(); this.command(c, cx); cx.notify(); }
    });
  }

  command(name, cx) {
    const cards = this.shown(), card = this.url ? this.current() : cards[this.selected];
    if (name === "next") this.select(Math.min(this.selected + 1, cards.length - 1));
    else if (name === "prev") this.select(this.selected - 1);
    else if (name === "open" && card) this.openPr(card.url, cx);
    else if (name === "back") this.back(cx);
    else if (name === "agent") this.goToAgent(card);
    else if (name === "github" && card) openExternal(card.url);
    else if (name === "refresh") this.refreshNow(cx);
    else if (name === "settings") this.settingsOpen = !this.settingsOpen;
    else if (name.startsWith("lang-")) setShared(LANG_KEY, name.slice(5));
    else if (name === "first-run" && card?.flow) { const r = flowRows(card, this.t, Date.now())[0]; if (r) this.toggleRun(card, r.id, cx); }
    else if (name === "last-run" && card?.flow) { const r = flowRows(card, this.t, Date.now()).at(-1); if (r) this.toggleRun(card, r.id, cx); }
    else if (name === "run-log" && card?.flow) { const r = flowRows(card, this.t, Date.now()).find((x) => x.failed); if (r) this.openViewer({ kind: "log", repo: card.repo, runId: String(r.id), name: r.label, url: r.url, title: card.pr.title, number: card.number }); }
    else if (name === "first-issue" && card?.issues?.[0]) this.openIssue(card.issues[0].url, cx);
    else if (name === "issue-back") this.issueUrl = null;
    else if (name === "checks") this.toggle("checks");
    else if (name === "first-file" && card?.pr?.files?.[0]) this.showFile(card, card.pr.files[0].path);
    else if (name === "log" && card) { const l = this.logFor(card); if (l?.tail) this.showLog(card, l); }
  }

  toggle(key) {
    if (this.opened.has(key)) this.opened.delete(key); else this.opened.add(key);
  }

  toggleRun(card, runId, cx) {
    this.toggle(`run-${runId}`);
    if (!this.opened.has(`run-${runId}`)) return;
    cx.spawn(async (cx) => { await this.tracker.loadJobs(card.url, runId); cx.notify(); });
  }

  openIssue(url, cx) {
    this.issueUrl = url;
    this.handle.focus();
    cx.spawn(async (cx) => {
      try { this.issueData.set(url, await this.gh.fetchIssue(url)); }
      catch { if (!this.issueData.has(url)) this.issueData.set(url, { failed: true }); }
      cx.notify();
    });
  }

  showFile(card, path) {
    const { pr } = card;
    this.openViewer({ kind: "diff", url: card.url, path, title: pr.title, number: card.number, additions: pr.additions, deletions: pr.deletions });
  }

  showLog(card, log) {
    this.openViewer({ kind: "log", repo: log.repo, runId: log.runId, name: log.name, url: log.url, title: card.pr.title, number: card.number });
  }

  // Saved in shared state, so the viewer pane follows the panel. A layout's `lang` prop is the default.
  langChoice() {
    return shared(LANG_KEY) ?? props()?.lang ?? "auto";
  }

  useLang() {
    const lang = effectiveLang(this.langChoice(), this.system);
    if (lang !== this.lang) { this.lang = lang; this.t = translator(lang); }
  }

  signature() {
    return JSON.stringify(this.tracker.cards(this.url).map((c) => [c.url, c.pr?.updatedAt, c.pr?.state, c.status?.name, c.status?.review, c.status?.comments, c.status?.ci?.kind, c.status?.ci?.checks?.map((x) => x.state), c.comments?.length, c.reviews?.length, c.threads?.length, c.agent?.address, c.agent?.status, c.issues?.map((i) => i.state), c.flow?.active, c.flow?.runs?.map((r) => [r.id, r.status, r.conclusion]), Object.values(c.flow?.jobs ?? {}).map((j) => j.jobs.map((x) => x.steps.map((y) => y.status)))])) + this.tracker.lastError();
  }

  // Polls only while it can be seen: the window is active and the layout shows this copy.
  tick(cx) {
    if (!appWindow()?.active || !this.visible()) { this.stale = true; return; }
    if (this.busy) return;
    this.busy = true;
    const before = this.signature();
    cx.spawn(async (cx) => {
      try {
        await this.tracker.tick(this.url);
      } finally { this.busy = false; }
      if (this.signature() !== before) { this.syncLog(cx); cx.notify(); }
    });
  }

  // The layout's side panel holds its copy in a stack: hidden, or behind another child, it isn't seen.
  visible() {
    return !props()?.panel || shownIn(layout()) !== false;
  }

  refreshNow(cx) {
    this.refreshing = true;
    this.ghReady = true;
    cx.notify();
    cx.spawn(async (cx) => {
      await this.tracker.refresh(this.url);
      this.ghReady = await this.gh.authOk().catch(() => false);
      this.refreshing = false;
      this.syncLog(cx);
      cx.notify();
    });
  }

  current() {
    return this.url ? this.tracker.cards(this.url).find((c) => c.url === this.url) ?? null : null;
  }

  openPr(url, cx, fromRender = false) {
    this.url = url;
    // Focus and notify are input-time effects; from render they error once.
    if (!fromRender) this.handle.focus();
    cx.spawn(async cx => {
      await this.tracker.tick(url);
      this.syncLog(cx);
      cx.notify();
    });
    if (!fromRender) cx.notify();
  }

  back(cx) {
    this.url = null;
    this.issueUrl = null;
    this.handle.focus();
    cx.notify();
  }

  // Fetches the failed CI log for the open PR once per run.
  syncLog(cx) {
    const card = this.current();
    const failed = card?.status?.ci?.failed?.[0];
    const runId = runIdFromUrl(failed?.url);
    if (!runId || this.logs.has(runId)) return;
    const entry = { name: failed.name, runId, repo: card.repo, url: failed.url, tail: null, failed: false };
    this.logs.set(runId, entry);
    cx.spawn(async (cx) => {
      try { entry.tail = logTail(sanitize(await this.gh.failedLog(card.repo, runId))); }
      catch { entry.failed = true; }
      cx.notify();
    });
  }

  logFor(card) {
    const failed = card.status?.ci?.failed?.[0];
    if (!failed) return null;
    const runId = runIdFromUrl(failed.url);
    return runId ? this.logs.get(runId) ?? null : { name: failed.name, url: failed.url, external: true };
  }

  // Shared "ci.select" tells ci-dash which repo and commit to show (and a run to open); then its panel.
  viewInCi(card, runId = card.status?.ci?.failed?.find((c) => c.runId)?.runId) {
    setShared("ci.select", { repo: card.repo, number: card.number, sha: card.pr?.headRefOid ?? null, runId: runId ?? null, at: Date.now() });
    run("layout.select", { stack: "panel-body", child: "ci" });
  }

  goToAgent(card) {
    if (card?.agent) run("agent.focus", { terminal: card.agent.address });
  }

  // One viewer pane at a time: a second file replaces what it shows.
  openViewer(target) {
    setShared(VIEW_KEY, { ...target, at: Date.now() });
    const all = panes();
    const open = all.find((p) => p.mod === MOD);
    if (open) { run("pane.focus", { pane: open.pane }); return; }
    const f = focused();
    const beside = all.find((p) => p.pane === f?.pane) ?? all.find((p) => p.tab === f?.tab && p.terminal);
    if (beside) run("pane.split", { direction: "right", pane: beside.pane, mod: MOD, props: { screen: "viewer" } });
    else run("tab.new", { name: "PR", mod: MOD, props: { screen: "viewer" } });
  }

  onKey(e, cx) {
    const cards = this.shown();
    if (this.settingsOpen) {
      const step = e.key === "j" || e.key === "down" ? 1 : e.key === "k" || e.key === "up" ? -1 : 0;
      if (step) setShared(LANG_KEY, LANGS[Math.max(0, Math.min(LANGS.length - 1, LANGS.indexOf(this.langChoice()) + step))]);
      else if (e.key === "escape" || e.key === "backspace") this.settingsOpen = false;
      else return;
    } else if (this.issueUrl) {
      if (e.key === "o") openExternal(this.issueUrl);
      else if (e.key === "escape" || e.key === "backspace") this.issueUrl = null;
      else return;
    } else if (this.url) {
      const card = this.current();
      if (e.key === "escape" || e.key === "backspace") this.back(cx);
      else if (e.key === "enter" || e.key === "g") this.goToAgent(card);
      else if (e.key === "o" && card) openExternal(card.url);
      else return;
    } else {
      if (e.key === "j" || e.key === "down") this.select(Math.min(this.selected + 1, cards.length - 1));
      else if (e.key === "k" || e.key === "up") this.select(Math.max(this.selected - 1, 0));
      else if (e.key === "enter" && cards[this.selected]) { this.openPr(cards[this.selected].url, cx); return; }
      else if (e.key === "g") this.goToAgent(cards[this.selected]);
      else if (e.key === "o" && cards[this.selected]) openExternal(cards[this.selected].url);
      else if (e.key === "r") { this.refreshNow(cx); return; }
      else return;
    }
    cx.stop_propagation();
    cx.notify();
  }

  select(index) {
    this.selected = Math.max(0, index);
    this.selectedUrl = this.shown()[this.selected]?.url;
    // Keeps the row in sight; the first brings its group label along.
    const entry = this.entryOf?.[this.selected];
    if (entry != null) this.scroll.scroll_to_item(this.selected === 0 ? 0 : entry);
  }

  // A badge's explicit scope wins; otherwise follow the selected space's cwd.
  syncScope(cx) {
    this.tracker.sync(shared("tui-spaces.prs"));
    const space = spaces().find(s => s.active);
    const tabs = new Set((space?.tabs ?? []).map(t => t.id));
    const pane = panes().find(p => tabs.has(p.tab) && p.cwd);
    this.branch = pane?.branch ?? space?.branch;
    const cwd = pane?.cwd ?? space?.folder;
    const key = JSON.stringify([space?.machine ?? null, cwd]);
    const want = shared("pr.select");
    if (key !== this.scopeKey) {
      this.scopeKey = key;
      this.scopeAt = Date.now();
      this.url = null;
      this.repo = null;
    }
    // A badge click is newer than the last space switch; switching spaces moves on.
    const explicit = want?.at > this.scopeAt ? want.repo : null;
    if (explicit) this.repo = explicit;
    else if (cwd && this.remotes.has(key)) this.repo = this.remotes.get(key);
    else if (cwd) {
      this.remotes.set(key, null); // includes failures: no render-time retry storm
      cx.spawn(async cx => {
        let repo = null;
        try {
          const r = await exec("git", ["remote", "get-url", "origin"], { cwd, on: space?.machine });
          if (r.code === 0) repo = parseRemote(r.stdout);
        } catch {}
        this.remotes.set(key, repo);
        if (this.scopeKey === key && !(shared("pr.select")?.at > this.scopeAt)) this.repo = repo;
        cx.notify();
      });
    }
    const selection = JSON.stringify(want ?? null);
    if (selection !== this.selection) {
      const card = explicit ? this.shown().find(c => c.number === want.number) : null;
      if (!explicit || card) this.selection = selection;
      this.issueUrl = null;
      this.settingsOpen = false;
      if (card) this.openPr(card.url, cx, true);
    }
  }

  shown() {
    return orderCards(this.tracker.cards().filter(c => c.repo === this.repo), this.branch);
  }

  header(count, t) {
    const tr = this.t;
    return h_flex().h(42).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().flex_none().font_semibold().child(tr("title")))
      .when(count > 0, (e) => e.child(div().px(6).rounded(5).bg(t.raised).text_size(11).text_color(t.muted).child(String(count))))
      // Which repo this list is: a badge click can point it away from the selected space.
      .when(Boolean(this.repo), (e) => e.child(div().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.repo.split("/").slice(-1)[0])))
      .child(div().flex_1())
      .child(h_flex().id("settings").size(26).flex_none().items_center().justify_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover)).tooltip(tr("settings"))
        .on_click((_e, cx) => { this.settingsOpen = true; cx.notify(); })
        .child(icon("settings", 14, t.muted)))
      .child(h_flex().id("refresh").size(26).flex_none().items_center().justify_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover)).tooltip(`${tr("refresh")}  r`)
        .on_click((_e, cx) => this.refreshNow(cx))
        .child(this.refreshing ? icon("spinner", 14, t.muted).spin(900) : icon("refresh", 14, t.muted)));
  }

  rowHeight(card) {
    const lines = card.pr ? 3 + (flowLine(card, this.t) ? 1 : 0) + (card.agent ? 1 : 0) : 2;
    return ROW_PAD * 2 + TITLE_H + (lines - 1) * (LINE_H + LINE_GAP);
  }

  // Drawn inside the virtual list: no handlers here, the list's on_item_click opens it.
  row(card, index, height, t) {
    const tr = this.t, now = Date.now();
    const done = card.pr?.state === "MERGED" && !card.flow?.active;
    const selected = index === this.selected;
    const short = card.repo.split("/")[1];
    const line = () => h_flex().w_full().h(LINE_H).flex_none().items_center();
    const body = v_flex().id(`pr-${index}`).w_full().h(height).flex_none().px(8).py(ROW_PAD).gap(LINE_GAP).rounded(8).cursor_pointer().when(selected, (e) => e.bg(t.selected)).hover((s) => s.bg(selected ? t.selected : t.hover));
    if (!card.pr) {
      return body
        .child(div().w_full().h(TITLE_H).flex_none().truncate().text_color(t.muted).child(`${short} #${card.number}`))
        .child(line().child(div().min_w(0).truncate().text_size(12).text_color(card.error ? t.ansi1 : t.dim).child(card.error ? sanitize(card.error) : tr("loading"))));
    }
    return body
      .child(div().w_full().h(TITLE_H).flex_none().truncate().font_medium().text_color(done || card.bot ? t.muted : t.foreground).child(card.pr.title))
      .child(line().gap(6).text_size(11).text_color(t.dim)
        .child(div().min_w(0).truncate().child(`${short} #${card.number}`))
        .when(!card.mine && Boolean(card.author), (e) => e.child(div().flex_none().child("·")).child(div().min_w(0).max_w(120).truncate().child(sanitize(card.author.replace(/^app\//, "")))))
        .child(div().flex_none().child("·"))
        .child(div().flex_none().child(issueLabel(card, tr)))
        .child(div().flex_1())
        .when(Boolean(card.pr.updatedAt), e => e.child(div().flex_none().child(relative(now - Date.parse(card.pr.updatedAt), tr)))))
      .child(line().gap(10).overflow_hidden().children(facts(card, tr).map((f) => fact(f, t))))
      .when(Boolean(flowLine(card, tr)), (e) => { const fl = flowLine(card, tr); return e.child(line().gap(5)
        .child(factIcon(fl.tone, t))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(fl.tone === "ok" ? t.muted : toneColor(t, fl.tone)).child(sanitize(fl.label)))
        .when(Boolean(fl.more), (x) => x.child(div().flex_none().text_size(11).text_color(t.dim).child(fl.more)))); })
      .when(Boolean(card.agent), (e) => e.child(line().gap(6)
        .child(h_flex().id(`agent-${index}`).size(14).flex_none().items_center().justify_center().tooltip(tr(`a_${card.agent.status}`)).child(agentMark(card.agent.status, t)))
        .child(div().min_w(0).truncate().text_size(12).text_color(t.muted).child(`${card.agent.app} · ${card.agent.name}`))));
  }

  list(t) {
    const tr = this.t, cards = this.shown();
    if (!cards.length) {
      const noGh = !this.ghReady;
      return v_flex().size_full().child(this.header(0, t))
        .child(v_flex().flex_1().items_center().justify_center().gap(6).px(24)
          .child(icon("merge", 22, t.dim))
          .child(div().pt(4).font_medium().child(tr(noGh ? "gh_title" : "empty_title")))
          .child(div().text_center().text_size(12).text_color(t.dim).child(tr(noGh ? "gh_body" : "empty_body"))));
    }
    // The selection stays on its PR when a new one pushes the rows down.
    const kept = cards.findIndex((c) => c.url === this.selectedUrl);
    this.selected = kept >= 0 ? kept : Math.min(this.selected, cards.length - 1);
    this.selectedUrl = cards[this.selected].url;
    const error = this.tracker.lastError(), entries = this.entries(cards, t);
    return v_flex().size_full().child(this.header(cards.length, t))
      .child(div().flex_1().min_h(0).relative().px(4).pt(4)
        .child(v_virtual_list("pr-list", entries.length, entries.map((x) => x.h), (i) => entries[i]?.key ?? String(i), (range) => entries.slice(range.start, range.end).map((x) => x.el()))
          .track_scroll(this.scroll).size_full()
          .on_item_click((key, cx) => {
            const i = cards.findIndex((c) => c.url === key);
            if (i < 0) return; // a group label
            this.selected = i; this.selectedUrl = key; this.openPr(key, cx);
          }))
        .child(Scrollbar.vertical("pr-list").viewport_from_layout().absolute().inset_0()))
      .when(Boolean(error), (e) => e.child(div().flex_none().px(12).py(6).border_t(1).border_color(t.border).truncate().text_size(11).text_color(t.ansi1).child(sanitize(error))))
      .child(div().flex_none().px(12).py(6).border_t(1).border_color(t.border).truncate().text_size(11).text_color(t.dim).child(tr("keys")));
  }

  // The list's items: rows, with group labels only when the list holds both yours and others'.
  entries(cards, t) {
    const rows = cards.map((c, i) => { const h = this.rowHeight(c); return { key: c.url, h: h + 2, el: () => div().h(h + 2).pb(2).child(this.row(c, i, h, t)) }; });
    const mine = cards.filter((c) => c.mine).length;
    if (!mine || mine === cards.length) { this.entryOf = cards.map((_c, i) => i); return rows; }
    this.entryOf = cards.map((_c, i) => (i < mine ? i + 1 : i + 2));
    const label = (key, text, count, top) => ({ key, h: top + 22, el: () => h_flex().h(top + 22).flex_none().px(8).pt(top).pb(2).gap(6).items_center().text_size(12)
      .child(div().font_medium().text_color(t.muted).child(text))
      .child(div().text_color(t.dim).child(String(count))) });
    return [label("group-mine", this.t("group_mine"), mine, 4), ...rows.slice(0, mine),
      label("group-others", this.t("group_others"), cards.length - mine, 12), ...rows.slice(mine)];
  }

  settingsScreen(t) {
    const tr = this.t, choice = this.langChoice();
    const options = LANGS.map((value) => [value, value === "auto" ? tr("lang_auto") : value === "ko" ? "한국어" : "English"]);
    return v_flex().size_full()
      .child(h_flex().h(42).flex_none().px(8).gap(4).items_center().border_b(1).border_color(t.border)
        .child(h_flex().id("settings-back").h(22).px(6).gap(2).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => { this.settingsOpen = false; cx.notify(); })
          .child(icon("back", 14, t.muted)).child(div().text_size(12).text_color(t.muted).child(tr("back"))))
        .child(div().flex_1())
        .child(div().pr(6).font_semibold().child(tr("settings"))))
      .child(this.section(tr("language"), t))
      .child(v_flex().px(8).gap(1).children(options.map(([value, label]) =>
        h_flex().id(`lang-${value}`).w_full().h(32).flex_none().px(6).gap(8).items_center().rounded(6).cursor_pointer().when(choice === value, (e) => e.bg(t.selected)).hover((s) => s.bg(choice === value ? t.selected : t.hover))
          .on_click(() => setShared(LANG_KEY, value))
          .child(div().flex_1().child(label))
          .when(choice === value, (e) => e.child(icon("check", 13, t.ansi2))))));
  }

  section(title, t) {
    return div().px(14).pt(16).pb(8).text_size(12).font_medium().text_color(t.dim).child(title);
  }

  logBlock(card, t) {
    const tr = this.t, log = this.logFor(card);
    if (!log) return null;
    const box = v_flex().id("log").w_full().p(10).rounded(8).bg(t.background).border_1().border_color(t.border).font_family(mono()).text_size(11).text_color(t.muted).cursor_pointer().hover((s) => s.border_color(t.input));
    if (log.external || log.failed) {
      return div().px(14).child(box.on_click(() => openExternal(log.url)).child(div().font_family(settings().ui_font_family ?? mono()).child(log.external ? tr("open_github") : tr("log_failed"))));
    }
    if (!log.tail) return div().px(14).child(box.child(div().child(tr("loading"))));
    return div().px(14).child(box
      .on_click(() => this.showLog(card, log))
      .children(log.tail.map((l) => div().w_full().truncate().child(l || " "))));
  }

  detail(card, t) {
    const tr = this.t, now = Date.now();
    const top = h_flex().h(42).flex_none().px(8).gap(4).items_center().border_b(1).border_color(t.border)
      .child(h_flex().id("back").h(22).px(6).gap(2).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.back(cx))
        .child(icon("back", 14, t.muted)).child(div().text_size(12).text_color(t.muted).child(tr("back"))))
      .child(div().flex_1())
      .child(h_flex().id("gh").h(22).px(6).gap(5).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover)).tooltip(`${tr("open_github")}  o`).on_click(() => openExternal(card.url))
        .child(div().text_size(12).text_color(t.muted).child("GitHub")).child(icon("external", 12, t.muted)));
    if (!card.pr || card.summary) {
      return v_flex().size_full().child(top).child(div().p(14).text_color(card.error ? t.ansi1 : t.dim).child(card.error ? sanitize(card.error) : tr("loading")));
    }
    const { pr, agent } = card;
    const files = pr.files ?? [], log = this.logBlock(card, t), logName = this.logFor(card)?.name;
    return v_flex().size_full().child(top)
      .child(v_flex().id("detail").flex_1().min_h(0).overflow_y_scrollbar()
        .child(this.identity(card, t, now))
        .when(Boolean(agent), (e) => e.child(div().px(14).pt(12).child(
          h_flex().id("agent").w_full().px(10).h(40).gap(8).items_center().rounded(8).bg(t.raised).cursor_pointer().hover((s) => s.bg(t.hover)).on_click(() => this.goToAgent(card))
            .child(h_flex().size(14).flex_none().items_center().justify_center().child(agentMark(agent.status, t)))
            .child(v_flex().flex_1().min_w(0)
              .child(div().truncate().child(agent.name))
              .child(div().truncate().text_size(11).text_color(t.dim).child(`${agent.app} · ${tr(`a_${agent.status}`)}`)))
            .child(div().flex_none().text_size(12).text_color(t.muted).child(tr("agent_go"))).child(icon("arrow", 12, t.muted)))))
        .child(this.statusList(card, t, now))
        .when(Boolean(log), (e) => e.child(this.section(tr("failed_log", logName), t)).child(log))
        .child(this.conversationSection(card, t, now))
        .child(this.heading(tr("files"), String(pr.changedFiles ?? files.length), t)
          .child(div().flex_1()).child(div().text_size(12).text_color(t.ansi2).child(`+${pr.additions ?? 0}`)).child(div().text_size(12).text_color(t.ansi1).child(`−${pr.deletions ?? 0}`)))
        .child(v_flex().px(8).children(files.map((f, i) => {
          const { dir, name } = fileLine(f.path);
          return h_flex().id(`f-${i}`).w_full().h(28).flex_none().px(6).gap(6).items_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
            .on_click(() => this.showFile(card, f.path))
            .child(h_flex().flex_1().min_w(0).child(div().min_w(0).truncate().text_color(t.dim).child(dir)).child(div().flex_none().max_w(220).truncate().child(name)))
            .child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${f.additions}`)).child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${f.deletions}`));
        })))
        .when(Boolean(pr.body?.trim()), (e) => e.child(this.description(card, t)))
        .child(div().h(16).flex_none()));
  }

  // A zone's title. Zones are told apart by space and this, not by boxes.
  heading(title, count, t) {
    return h_flex().px(14).pt(24).pb(8).gap(6).items_center()
      .child(div().text_size(13).font_semibold().child(title))
      .when(Boolean(count), (e) => e.child(div().text_size(12).text_color(t.dim).child(count)));
  }

  // Title, then one line of what it is and one of where it goes.
  identity(card, t, now) {
    const tr = this.t, { pr } = card, name = card.status.name;
    const state = name === "merged" || name === "closed" || name === "draft" ? name : "open";
    const dot = () => div().flex_none().child("·");
    return v_flex().px(14).pt(14).gap(6)
      .child(div().text_size(16).font_semibold().child(pr.title))
      .child(h_flex().w_full().gap(6).items_center().text_size(11).text_color(t.dim)
        .child(div().size(7).flex_none().rounded(99).bg(toneColor(t, PR_STATE_TONE[state])))
        .child(div().flex_none().text_color(t.muted).child(tr(state)))
        .when(Boolean(card.author), (e) => e.child(dot()).child(div().flex_none().max_w(120).truncate().child(sanitize(card.author.replace(/^app\//, "")))))
        .when(Boolean(pr.updatedAt), (e) => e.child(dot()).child(div().flex_none().child(relative(now - Date.parse(pr.updatedAt), tr))))
        .child(div().flex_1())
        .child(div().min_w(0).truncate().child(card.repo.split("/").at(-1)))
        .child(div().flex_none().child(`#${card.number}`)))
      .child(h_flex().gap(5).items_center().text_size(12).text_color(t.muted).child(icon("branch", 12, t.dim)).child(div().min_w(0).truncate().child(`${pr.headRefName} → ${pr.baseRefName}`)));
  }

  // Where the PR is, as aligned field/value lines: CI, review, merge, runs after merge, issues.
  statusList(card, t, now) {
    const tr = this.t;
    const rows = statusRows(card, tr, now).map((row) => this.statusRow(card, row, t));
    const runs = flowRows(card, tr, now).map((row, i) => this.statusRow(card, { ...row, key: `run-${row.id}`, field: i ? "" : tr("after_merge"), run: true }, t));
    return v_flex().px(8).pt(14).children([...rows, ...runs, ...this.issueRows(card, t)]);
  }

  fieldLine(id, field, t) {
    return h_flex().id(id).w_full().min_h(28).flex_none().px(6).gap(8).items_center().rounded(6)
      .child(div().w(FIELD_W).flex_none().truncate().text_size(12).text_color(t.dim).child(field));
  }

  // One status fact; CI and runs open in place to their checks or steps.
  statusRow(card, row, t) {
    // Checks that all live outside GitHub Actions stay listed: their pages are the only details.
    const ci = card.status?.ci, external = Boolean(row.checks) && !ci?.actions;
    const tr = this.t, key = row.run ? row.key : "checks", openable = Boolean(row.run || row.checks) && !external, opened = external || (openable && this.opened.has(key));
    const toggle = (_e, cx) => { if (row.run) this.toggleRun(card, row.id, cx); else this.toggle(key); cx.notify(); };
    const link = (id, label, onClick) => h_flex().id(id).h(22).px(6).items_center().rounded(5).text_size(12).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(onClick).child(label);
    const sub = opened ? this.subRows(card, row, t) : null, indent = 6 + FIELD_W + 8;
    return v_flex().w_full().flex_none()
      .child(this.fieldLine(`st-${row.key}`, row.field, t).when(openable, (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click(toggle))
        .child(row.key === "merge" && row.tone === "warn" ? icon("merge", 12, t.blocked) : factIcon(row.tone, t))
        .child(div().min_w(0).truncate().font_medium().text_color(valueColor(t, row.tone)).child(sanitize(row.label)))
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(sanitize(row.note ?? "")))
        .when(openable, (e) => e.child(icon(opened ? "down" : "arrow", 11, t.dim))))
      // The links' text lines up with the value above; their padding hangs to the left.
      .when(Boolean(row.run) && (opened || row.failed), (e) => e.child(h_flex().pl(indent + 14).pb(4).gap(2)
        .when(row.failed, (x) => x.child(link(`log-${row.id}`, tr("run_log"), () => this.openViewer({ kind: "log", repo: card.repo, runId: String(row.id), name: row.label, url: row.url, title: card.pr.title, number: card.number }))))
        .child(link(`web-${row.id}`, "GitHub", () => openExternal(row.url)))))
      .when(Boolean(sub), (e) => e.child(div().pl(indent).pr(6).pb(8).child(sub)))
      // The CI panel (ci-dash) has the jobs, logs, artifacts and re-run: this PR's Actions runs there.
      .when(Boolean(row.checks) && Boolean(ci?.actions), (e) => e.child(h_flex().pl(indent + 14).pb(4)
        .child(link("ci-more", ci.runs > 1 ? tr("view_ci_n", ci.runs) : tr("view_ci"), () => this.viewInCi(card)))));
  }

  // Closing issues open in the panel; Jira and Linear keys open the issues popup.
  issueRows(card, t) {
    const tr = this.t, issues = card.issues ?? [], refs = issueRefs(card.pr.body, shared("issues.refs"));
    const rows = issues.map((issue, i) => {
      const state = issueState(issue, tr);
      return this.fieldLine(`issue-${i}`, i ? "" : tr("issues"), t).cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.openIssue(issue.url, cx))
        .child(h_flex().size(12).flex_none().items_center().justify_center().child(div().size(7).rounded(99).bg(toneColor(t, state.tone))))
        .child(div().flex_none().text_size(12).text_color(t.dim).child(`#${issue.number}`))
        .child(div().flex_1().min_w(0).truncate().child(sanitize(issue.title)))
        .child(div().flex_none().text_size(12).text_color(t.muted).child(state.label));
    });
    if (refs.length) {
      rows.push(this.fieldLine("refs", issues.length ? "" : tr("issues"), t).child(h_flex().flex_1().min_w(0).py(3).gap(4).flex_wrap().children(refs.map((ref) =>
        h_flex().id(`ref-${ref.provider}-${ref.key}`).h(22).px(7).items_center().rounded(5).bg(t.raised).text_size(12).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => {
            setShared("issues.open", { provider: ref.provider, key: ref.key, at: Date.now() });
            run("mod.open", { name: "issues" });
          }).child(ref.key)))));
    }
    if (!rows.length) rows.push(this.fieldLine("issues", tr("issues"), t).child(icon("pending", 10, t.dim)).child(div().text_color(t.dim).child(tr("s_none"))));
    return rows;
  }

  // Comments, reviews and open threads, oldest first. People in full; bots folded.
  conversationSection(card, t, now) {
    const tr = this.t, entries = conversation(card);
    const count = entries.reduce((n, x) => n + (x.kind === "bots" ? x.items.length : 1), 0);
    const ago = (at) => relative(now - Date.parse(at), tr);
    return v_flex().w_full().flex_none()
      .child(this.heading(tr("conversation"), count ? String(count) : "", t))
      .when(!entries.length, (e) => e.child(div().px(14).text_size(12).text_color(t.dim).child(tr("no_comments"))))
      .child(v_flex().px(8).gap(2).children(entries.map((x, i) =>
        x.kind === "bots" ? this.botGroup(x, `${card.number}-${i}`, t, ago) : x.bot ? this.botPost(x, `${card.number}-${i}`, t, ago) : this.post(x, `${card.number}-${i}`, t, ago))));
  }

  post(x, id, t, ago) {
    const tr = this.t, review = x.state === "APPROVED" || x.state === "CHANGES_REQUESTED";
    const tag = x.kind === "thread" ? sanitize(x.where.split("/").at(-1)) : review ? tr(`rv_${x.state}`) : "";
    return v_flex().w_full().flex_none().px(6).pt(6).pb(10).gap(4)
      .child(h_flex().w_full().gap(6).items_center().text_size(12)
        .child(div().flex_none().max_w(150).truncate().font_medium().child(x.who))
        .when(Boolean(tag), (e) => e.child(div().min_w(0).truncate().text_color(x.state === "APPROVED" ? t.ansi2 : x.state === "CHANGES_REQUESTED" ? t.blocked : t.dim).child(tag)))
        .child(div().flex_1())
        .child(div().flex_none().text_size(11).text_color(t.dim).child(ago(x.at))))
      .child(TextView.markdown(`cv-${id}`, x.body).text_size(13).text_color(t.foreground));
  }

  // A bot's post: one dim line until opened.
  botPost(x, id, t, ago) {
    const key = `c:${x.key}`, opened = this.opened.has(key);
    return v_flex().w_full().flex_none()
      .child(h_flex().id(`cv-${id}`).w_full().h(26).px(6).gap(6).items_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { this.toggle(key); cx.notify(); })
        .child(icon(opened ? "down" : "arrow", 10, t.dim))
        .child(div().flex_none().max_w(120).truncate().text_size(12).text_color(t.muted).child(x.who))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(x.line))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(ago(x.at))))
      .when(opened, (e) => e.child(div().pl(22).pr(6).pt(2).pb(10).child(TextView.markdown(`cvb-${id}`, x.body).text_size(12).text_color(t.muted))));
  }

  // Back-to-back bot posts: one line that opens to their own folded lines.
  botGroup(g, id, t, ago) {
    const tr = this.t, key = `g:${g.key}`, opened = this.opened.has(key);
    return v_flex().w_full().flex_none()
      .child(h_flex().id(`cvg-${id}`).w_full().h(26).px(6).gap(6).items_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { this.toggle(key); cx.notify(); })
        .child(icon(opened ? "down" : "arrow", 10, t.dim))
        .child(div().flex_none().text_size(12).text_color(t.muted).child(tr("bot_comments", g.items.length)))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child([...new Set(g.items.map((x) => x.who))].join(", ")))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(ago(g.items.at(-1).at))))
      .when(opened, (e) => e.child(v_flex().pl(16).children(g.items.map((x, j) => this.botPost(x, `${id}-${j}`, t, ago)))));
  }

  // Long descriptions open on their first paragraph; the rest is a click away.
  description(card, t) {
    const tr = this.t, key = `desc:${card.url}`, { preview, more } = descPreview(card.pr.body), full = !more || this.opened.has(key);
    return v_flex().w_full().flex_none()
      .child(this.heading(tr("description"), "", t))
      .when(full || Boolean(preview), (e) => e.child(div().px(14).text_size(13).child(TextView.markdown(`body-${card.number}-${full ? "full" : "head"}`, full ? card.pr.body : preview))))
      .when(more, (e) => e.child(h_flex().px(8).pt(4).child(h_flex().id("desc-more").h(22).px(6).gap(4).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { this.toggle(key); cx.notify(); })
        .child(div().text_size(12).text_color(t.muted).child(tr(full ? "show_less" : "show_more")))
        .when(!full, (x) => x.child(icon("down", 11, t.dim))))));
  }

  miniIcon(tone, t) {
    const c = toneColor(t, tone);
    if (tone === "ok") return icon("check", 11, c);
    if (tone === "bad") return icon("cross", 11, c);
    if (tone === "run") return icon("spinner", 10, c).spin(900);
    return icon("pending", 9, tone === "wait" ? t.foreground : t.dim);
  }

  // A workflow's steps, or the PR's checks, under their timeline row.
  subRows(card, row, t) {
    if (row.checks) {
      const tr = this.t, checks = [...card.status.ci.checks, ...card.status.ci.ai];
      // Actions checks open their run in the CI panel; others open their own page.
      return v_flex().w_full().pt(5).gap(3).children(checks.map((c, i) => {
        const open = c.source === "actions" ? () => this.viewInCi(card, c.runId) : c.url ? () => openExternal(c.url) : null;
        return h_flex().id(`check-${i}`).w_full().gap(6).items_center().rounded(5)
          .when(Boolean(open), (e) => e.cursor_pointer().hover((s) => s.bg(t.hover)).on_click(open))
          .child(this.miniIcon(c.state === "passed" ? "ok" : c.state === "failed" ? "bad" : "run", t))
          .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.muted).child(sanitize(c.name)))
          .when(c.source !== "actions", (e) => e.child(div().flex_none().text_size(11).text_color(t.dim).child(tr("external")))
            .when(Boolean(c.url), (x) => x.child(icon("external", 11, t.dim))));
      }));
    }
    if (!row.run || !this.opened.has(`run-${row.id}`)) return null;
    const jobs = jobSteps(card.flow.jobs?.[row.id]?.jobs);
    if (!jobs.length) return div().pt(5).text_size(12).text_color(t.dim).child(this.t("loading"));
    return v_flex().w_full().pt(5).gap(3).children(jobs.flatMap((job) => [
      ...(jobs.length > 1 ? [h_flex().w_full().pt(2).gap(6).items_center().child(this.miniIcon(job.tone, t)).child(div().min_w(0).truncate().text_size(12).font_medium().child(sanitize(job.name)))] : []),
      ...job.steps.map((x) => h_flex().w_full().gap(6).items_center().when(jobs.length > 1, (e) => e.pl(10))
        .child(this.miniIcon(x.tone, t))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(x.tone === "todo" ? t.dim : t.muted).child(sanitize(x.name)))),
    ]));
  }

  issueScreen(url, t) {
    const tr = this.t, card = this.current(), issue = this.issueData.get(url);
    const top = h_flex().h(42).flex_none().px(8).gap(4).items_center().border_b(1).border_color(t.border)
      .child(h_flex().id("issue-back").h(22).px(6).gap(2).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_e, cx) => { this.issueUrl = null; cx.notify(); })
        .child(icon("back", 14, t.muted)).child(div().text_size(12).text_color(t.muted).child(`PR #${card?.number ?? ""}`)))
      .child(div().flex_1())
      .child(h_flex().id("issue-gh").h(22).px(6).gap(5).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(t.hover)).tooltip(`${tr("open_github")}  o`).on_click(() => openExternal(url))
        .child(div().text_size(12).text_color(t.muted).child("GitHub")).child(icon("external", 12, t.muted)));
    if (!issue || issue.failed) return v_flex().size_full().child(top).child(div().p(14).text_color(issue ? t.ansi1 : t.dim).child(issue ? tr("issue_failed") : tr("loading")));
    const state = issueState(issue, tr), comments = issue.comments ?? [], now = Date.now();
    return v_flex().size_full().child(top)
      .child(v_flex().id("issue").flex_1().min_h(0).overflow_y_scrollbar()
        .child(v_flex().px(14).pt(14).gap(6)
          .child(div().text_size(16).font_semibold().child(sanitize(issue.title)))
          .child(h_flex().gap(6).items_center().text_size(11).text_color(t.dim)
            .child(div().size(8).flex_none().rounded(99).bg(toneColor(t, state.tone)))
            .child(div().text_color(t.muted).child(state.label))
            .child(div().min_w(0).truncate().child(`#${issue.number} · ${sanitize(issue.author?.login ?? "")} · ${relative(now - Date.parse(issue.createdAt), tr)}`)))
          .when((issue.labels ?? []).length > 0, (e) => e.child(h_flex().flex_wrap().gap(4).pt(2).children(issue.labels.map((l) => div().px(6).rounded(5).bg(t.raised).text_size(11).text_color(t.muted).child(sanitize(l.name)))))))
        .when(Boolean(issue.body?.trim()), (e) => e.child(div().px(14).pt(14).text_size(13).child(TextView.markdown(`issue-${issue.number}`, sanitize(issue.body)))))
        .when(comments.length > 0, (e) => e.child(this.section(tr("issue_comments", comments.length), t)).child(v_flex().px(14).gap(8).children(comments.slice(-20).map((c, i) =>
          v_flex().w_full().p(10).gap(4).rounded(8).bg(t.raised)
            .child(h_flex().w_full().gap(6).text_size(11).text_color(t.dim).child(div().min_w(0).truncate().child(sanitize(c.author?.login ?? ""))).child(div().flex_1()).child(div().flex_none().child(relative(now - Date.parse(c.createdAt), tr))))
            .child(div().text_size(13).child(TextView.markdown(`issue-${issue.number}-c${i}`, sanitize(c.body))))))))
        .child(div().h(16).flex_none()));
  }

  // The viewer pane: a PR's diff or a CI log, wide enough to read.
  loadViewer(target, cx) {
    this.loaded = target.at;
    this.target = target;
    this.files = null; this.lines = null; this.viewError = false; this.file = 0;
    const gh = createGh(exec);
    cx.spawn(async (cx) => {
      try {
        if (target.kind === "log") this.lines = sanitize(await gh.failedLog(target.repo, target.runId)).split("\n");
        else {
          this.files = parseDiff(await gh.fetchDiff(target.url)).map((f) => ({ ...f, lines: f.lines.map((l) => ({ ...l, text: sanitize(l.text) })) }));
          this.file = Math.max(0, this.files.findIndex((f) => f.path === target.path));
        }
      } catch { this.viewError = true; }
      // Opened from the panel, so the keyboard comes along: Esc closes it.
      if (this.target === target) { this.handle.focus(); cx.notify(); }
    });
  }

  closeViewer() {
    const mine = panes().find((p) => p.mod === MOD);
    if (mine) run("pane.close", { pane: mine.pane });
  }

  viewerRow(l, t) {
    if (l.kind === "hunk" || l.kind === "meta") return h_flex().w_full().h(20).flex_none().px(12).items_center().bg(t.raised).text_color(t.dim).child(div().truncate().child(l.text || "⋯"));
    const add = l.kind === "add", del = l.kind === "del";
    return h_flex().w_full().h(20).flex_none().items_center().when(add, (e) => e.bg(tint(t.ansi2, "18", t.hover))).when(del, (e) => e.bg(tint(t.ansi1, "18", t.hover)))
      .child(div().w(38).flex_none().text_right().text_color(t.dim).child(l.oldNo === undefined ? "" : String(l.oldNo)))
      .child(div().w(38).flex_none().text_right().text_color(t.dim).child(l.newNo === undefined ? "" : String(l.newNo)))
      .child(div().w(22).flex_none().text_center().text_color(add ? t.ansi2 : del ? t.ansi1 : t.dim).child(add ? "+" : del ? "-" : ""))
      .child(div().flex_1().whitespace_nowrap().child(l.text));
  }

  viewerBody(t) {
    const tr = this.t, target = this.target;
    if (this.viewError) {
      return v_flex().flex_1().items_center().justify_center().gap(10).px(24)
        .child(div().text_center().text_color(t.muted).child(tr(target.kind === "log" ? "log_failed" : "diff_failed")))
        .child(div().id("gh").px(10).py(5).rounded(6).bg(t.raised).cursor_pointer().hover((s) => s.bg(t.hover)).on_click(() => openExternal(target.url)).child(tr("open_github")));
    }
    if (target.kind === "log") {
      if (!this.lines) return div().p(14).text_color(t.dim).child(tr("loading"));
      const lines = this.lines;
      return div().flex_1().min_h(0).relative().font_family(mono()).text_size(12).child(div().id("log-x").size_full().overflow_x_scrollbar().child(div().min_w(Math.max(600, ...lines.map((l) => l.length * 7.2 + 40))).h_full().child(
        v_virtual_list("log", lines.length, 20, (i) => String(i), (r) => lines.slice(r.start, r.end).map((l) => div().h(20).flex_none().px(12).whitespace_nowrap().text_color(t.muted).child(l || " "))).size_full())))
        .child(Scrollbar.vertical("log").viewport_from_layout().absolute().inset_0());
    }
    if (!this.files) return div().p(14).text_color(t.dim).child(tr("loading"));
    if (!this.files.length) return div().p(14).text_color(t.dim).child(tr("no_diff"));
    const narrow = (this.size?.width ?? 800) < 620;
    const rows = this.files[this.file]?.lines ?? [];
    return h_flex().flex_1().min_h(0).items_start()
      .child(v_flex().id("files").w(narrow ? 150 : 220).flex_none().h_full().p(6).gap(1).border_r(1).border_color(t.border).overflow_y_scrollbar().children(this.files.map((f, i) => {
        const { dir, name } = fileLine(f.path);
        return v_flex().id(`vf-${i}`).w_full().flex_none().px(8).py(5).rounded(6).cursor_pointer().when(i === this.file, (e) => e.bg(t.selected)).hover((s) => s.bg(i === this.file ? t.selected : t.hover))
          .on_click((_e, cx) => { this.file = i; cx.notify(); })
          .child(div().w_full().truncate().child(name))
          .child(h_flex().w_full().gap(6).text_size(11).child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(dir)).child(div().flex_none().text_color(t.ansi2).child(`+${f.added}`)).child(div().flex_none().text_color(t.ansi1).child(`−${f.removed}`)));
      })))
      .child(div().flex_1().min_w(0).h_full().relative().font_family(mono()).text_size(12)
        .child(div().id("diff-x").size_full().overflow_x_scrollbar().child(div().w_full().min_w(Math.max(400, ...rows.map((l) => (l.text?.length ?? 0) * 7.2 + 130))).h_full().child(
          v_virtual_list(`diff-${this.file}`, rows.length, 20, (i) => String(i), (r) => rows.slice(r.start, r.end).map((l) => this.viewerRow(l, t))).size_full())))
        .child(Scrollbar.vertical(`diff-${this.file}`).viewport_from_layout().absolute().inset_0()));
  }

  renderViewer(t, cx) {
    const want = shared(VIEW_KEY);
    if (want && want.at !== this.loaded) this.loadViewer(want, cx);
    const target = this.target;
    return v_flex().id("viewer").size_full().track_focus(this.handle).on_mouse_down("left", () => this.handle.focus()).on_size_change((size, cx) => { this.size = size; cx.notify(); })
      .on_key_down((e, cx) => { if (e.key !== "escape") return; this.closeViewer(); cx.stop_propagation(); })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .when(Boolean(target), (e) => e
          .child(div().flex_none().font_semibold().child(`#${target.number}`))
          .child(div().min_w(0).truncate().text_color(t.muted).child(target.kind === "log" ? `${target.name} · ${target.title}` : target.title)))
        .child(div().flex_1())
        .when(target?.kind === "diff", (e) => e.child(div().flex_none().text_size(11).text_color(t.ansi2).child(`+${target.additions ?? 0}`)).child(div().flex_none().text_size(11).text_color(t.ansi1).child(`−${target.deletions ?? 0}`)))
        .child(h_flex().id("close").size(26).flex_none().items_center().justify_center().rounded(6).cursor_pointer().hover((s) => s.bg(t.hover)).tooltip(`${this.t("close")}  Esc`).on_click(() => this.closeViewer()).child(icon("cross", 14, t.muted))))
      .when(Boolean(target), (e) => e.child(this.viewerBody(t)));
  }

  render(cx) {
    this.useLang();
    const t = theme();
    // In the layout's side panel it sits flush: the panel draws the frame.
    const panel = Boolean(props()?.panel);
    const shell = v_flex().size_full().min_h(0).rounded(panel ? 0 : 10).overflow_hidden().bg(t.background).when(!panel, (e) => e.border_1().border_color(t.border)).when(panel, (e) => e.border_t(1).border_b(1).border_color(t.border)).text_color(t.foreground).text_size(13);
    // A pane already has Herdr's own frame around it.
    if (this.viewer) return v_flex().size_full().min_h(0).overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13).child(this.renderViewer(t, cx));
    if (this.stale) { this.stale = false; this.tick(cx); }
    this.syncScope(cx);
    const card = this.url ? this.current() : null;
    if (this.url && !card) this.url = null; // it closed while open
    return shell.id("pr-flow").track_focus(this.handle).on_key_down((e, cx) => this.onKey(e, cx)).on_mouse_down("left", () => this.handle.focus())
      .child(this.settingsOpen ? this.settingsScreen(t) : card && this.issueUrl ? this.issueScreen(this.issueUrl, t) : card ? this.detail(card, t) : this.list(t));
  }
}
