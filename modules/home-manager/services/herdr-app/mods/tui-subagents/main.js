// A popup listing an agent's live sub-agents (props().parent), all the way down, or the main agents a tui-spaces row
// counts (props().filter: {space, folder, except}, mainIn in space.js), most urgent status first; a click peeks at one.
// Opened from tui-focus cards' sub-agents line and tui-spaces' agents chip. Under a parent, hibernated workers
// (shared "tui-focus.hibernated") show a moon and
// how long ago; a click revives one where it was (same name, folder, parent, session), then peeks at it.
// A live worker on a branch of its own shows that branch's PR (tui-spaces' shared "tui-spaces.prs"), as a space row does.
// The keyboard works it too: j/k or the arrows pick a row, Enter peeks or revives, p opens the picked worker's PR
// in the PR panel, Esc closes; a footer under the rows says so.
// Rows keep one height each (LIVE, ASLEEP), the footer FOOT: openers size the popup from them (tui-focus, tui-spaces).

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, v_virtual_list, Scrollbar, VirtualListScrollHandle } from "gpui-base";
import { agents, terminals, theme, run, props, closeOverlay, exec, hc, shared, setShared, notify, window } from "herdr";
import { mainIn } from "./space.js";

const HIBERNATED = "tui-focus.hibernated";
// A row's height with the 2px under it: a live one has two lines (the second kept even empty, so a git answer
// arriving doesn't move the rows), a hibernated one a single line.
const LIVE = 50, ASLEEP = 32;
// The key footer, its hairline and the 2px above it; drawn, and counted by openers, only under rows.
const FOOT = 24;
// Indents stop here, so a deep tree keeps room for its names.
const DEPTH = 3;

// As tui-focus times: no "ago", nothing past days.
function ago(ms, now) {
  const m = Math.floor((now - ms) / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m`;
  if (m < 1440) return `${Math.floor(m / 60)}h`;
  return `${Math.floor(m / 1440)}d`;
}

// The finished terminal goes, and its resume line runs as a new one under the same parent, opted in again.
async function revive(r) {
  await hc(["rm", r.address]).catch(() => null);
  const args = ["run", "--bg", "--json", "--cwd", r.cwd, "--outlive-parent"];
  if (r.name) args.push("--name", r.name);
  if (terminals().some((k) => k.address === r.parent && k.state === "live")) args.push("--parent", r.parent);
  if (r.space) args.push("--label", `space=${r.space}`);
  const res = await hc([...args, ...r.line.split(" ")]).catch((e) => ({ code: 1, stderr: String(e) }));
  if (res.code !== 0) {
    notify({ title: "Couldn't revive the agent", body: `${r.title}: ${res.stderr.trim()}`, level: "error" });
    return;
  }
  setShared(HIBERNATED, (shared(HIBERNATED) ?? []).filter((x) => x.address !== r.address));
  const addr = JSON.parse(res.stdout).address;
  await hc(["label", addr, "hibernate=ok"]).catch(() => null);
  run("terminal.peek", { terminal: addr });
}

const icon = (p, size, color) => !p?.icon ? null
  : p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();

// Live sub-agents of `addr`, depth first, with their depth.
const tree = (all, addr, depth = 0) => all.filter((k) => k.parent === addr && k.state === "live")
  .flatMap((k) => [{ k, depth }, ...tree(all, k.address, depth + 1)]);
// What the popup lists: a space's main agents, else the parent's sub-agents.
const listOf = (all, p) => p?.filter ? mainIn(all, p.filter) : tree(all, p?.parent);
// Most urgent first, as a space's status goes: blocked > done > working > idle; no word last.
const URGENCY = ["blocked", "done", "working", "idle"];
const urgency = (s) => { const i = URGENCY.indexOf(s); return i < 0 ? URGENCY.length : i; };

const base = (path) => path.replace(/[\\/]+$/, "").split(/[\\/]/).pop() || path;

// Where a terminal works: its project (the main checkout's folder, so a worktree reads as its repo) and
// branch. Outside git: the folder's name, no branch. A terminal on another machine (`vps/t7`) runs git there.
// `common`, the repo's git folder, finds its PRs in tui-spaces' feed, which has only this machine's.
async function place(k) {
  const on = k.address.includes("/") ? k.address.split("/")[0] : undefined;
  try {
    const r = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir", "--abbrev-ref", "HEAD"], { cwd: k.cwd, on });
    const [common, branch] = r.stdout.trim().split("\n");
    if (r.code === 0 && common) return { project: base(common.replace(/[\\/]\.git$/, "")), branch: branch && branch !== "HEAD" ? branch : null, common: on ? null : common };
  } catch {}
  return { project: base(k.cwd), branch: null };
}

export default class SubAgents extends View {
  init(_props, cx) {
    // address → {project, branch, common}, for the parent and each sub-agent; re-read gently, as branches change.
    this.places = {};
    // The picked row, and the hibernated ones being revived (address): a second click on one does nothing.
    this.at = 0;
    this.reviving = new Set();
    this.scroll = VirtualListScrollHandle.new();
    this.keys = cx.focus_handle();
    this.keys.focus();
    this.refresh(cx);
    cx.timer.every(5000, (cx) => { if (window()?.active) this.refresh(cx); });
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      const parent = props()?.parent, all = terminals();
      const ks = [all.find((k) => k.address === parent), ...listOf(all, props()).map((r) => r.k)].filter((k) => k?.cwd);
      for (const k of ks) this.places[k.address] = await place(k);
      cx.notify();
    });
  }

  render() {
    const t = theme(), { parent, filter, overlay } = props() ?? {};
    // A sub-agent with a pane is in agents(); else its raw word, error counting as blocked.
    const listed = new Map(agents().map((a) => [a.address, a.status]));
    const word = (k) => { const s = listed.get(k.address) ?? k.status; return s === "error" ? "blocked" : s; };
    const color = { working: t.working, blocked: t.blocked, done: t.done, idle: t.idle };
    const rows = listOf(terminals(), props());
    // A space's main agents by status; a parent's tree keeps its depth-first order.
    if (filter) rows.sort((a, b) => urgency(word(a.k)) - urgency(word(b.k)));
    const mine = this.places[parent] ?? {};
    // A worker's PR: the open one on its branch in its repo, its author's first, as a space row's badge picks.
    // None on the parent's branch: that PR is the parent's.
    const prs = Object.entries(shared("tui-spaces.prs") ?? {}).flatMap(([repo, list]) => list.map((p) => ({ ...p, repo })));
    const prOf = (at) => {
      if (!at?.common || !at.branch || at.branch === mine.branch) return null;
      const on = prs.filter((p) => p.common === at.common && p.branch === at.branch);
      return on.find((p) => p.mine) ?? on[0] ?? null;
    };
    const under = new Set([parent, ...rows.map((r) => r.k.address)]), now = Date.now();
    // Hibernated workers are sub-agents: listed under their parent, never in a space's main agents.
    const sleeping = filter ? [] : (shared(HIBERNATED) ?? []).filter((r) => under.has(r.parent));
    // One list for the pointer and the keyboard: live rows, then hibernated ones.
    const items = [...rows.map((r) => ({ key: `sub:${r.k.address}`, h: LIVE, live: r, pr: prOf(this.places[r.k.address]) })),
      ...sleeping.map((r) => ({ key: `hib:${r.address}`, h: ASLEEP, asleep: r }))];
    this.at = Math.max(0, Math.min(this.at, items.length - 1));
    // Peeks at a live one; revives a hibernated one, then peeks. Closed after: closing first could cancel the
    // popup's own task.
    const choose = (x, cx) => {
      if (x.live) {
        closeOverlay(overlay);
        run("terminal.peek", { terminal: x.live.k.address });
        return;
      }
      const r = x.asleep;
      if (this.reviving.has(r.address)) return;
      this.reviving.add(r.address);
      cx.notify();
      cx.spawn(async () => {
        try { await revive(r); } finally { this.reviving.delete(r.address); closeOverlay(overlay); }
      });
    };
    // p: the picked worker's PR in the PR panel, as a space row's badge opens one. Closed last, after the commands.
    const openPr = (pr) => {
      if (!pr) return;
      setShared("pr.select", { repo: pr.repo, number: pr.number, at: Date.now() });
      run("layout.select", { stack: "panel-body", child: "pr" });
      run("layout.show", { id: "panel" });
      closeOverlay(overlay);
    };
    const step = (by) => {
      if (!items.length) return;
      this.at = (this.at + by + items.length) % items.length;
      this.scroll.scroll_to_item(this.at);
    };
    // CI as a mark that reads without its color (pr-flow's): passed, failed, running.
    const marks = { pass: ["check", t.done, "CI passing"], fail: ["cross", t.blocked, "CI failing"], pending: ["pending", t.working, "CI running"] };
    const liveRow = ({ k, depth }, on, pr) => {
      const st = word(k);
      // Second line: project and branch, each only when it differs from the parent's.
      const at = this.places[k.address] ?? {};
      const info = [at.project !== mine.project ? at.project : null, at.branch !== mine.branch ? at.branch : null].filter(Boolean);
      const pic = icon(k.program, 14, t.muted), name = k.name || k.template || k.program?.name || k.address;
      // Its PR, as a space row's badge draws it: display only (the row's click peeks; p opens it), never cut.
      const ci = marks[pr?.ci];
      const chip = pr ? h_flex().id(`pr-${k.address}`).flex_none().gap(3).items_center().text_size(11).text_color(t.muted)
        .tooltip([`PR #${pr.number}`, ci?.[2], pr.title].filter(Boolean).join(" · "))
        .accessibility_label([`PR #${pr.number}`, ci?.[2]].filter(Boolean).join(", "))
        .child(`#${pr.number}`)
        .when(Boolean(ci), (el) => el.child(svg(`mods/pr-flow/${ci?.[0]}.svg`).size(11).flex_none().text_color(ci?.[1]))) : null;
      // First line: name and status. Second: project/branch, its PR, and the agent icon on the right.
      return v_flex().id(`sub-${k.address}`).h(LIVE - 2).py(5).pl(8 + Math.min(depth, DEPTH) * 16).pr(8).rounded(6)
        .cursor_pointer().when(on, (el) => el.bg(t.selected)).hover((s) => s.bg(on ? t.selected : t.hover))
        .role("button").accessibility_label(`Peek at ${name}`)
        .child(h_flex().h(20).gap(8).items_center().min_w(0)
          .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(name))
          .child(div().flex_none().text_size(11).text_color(color[st] ?? t.unknown).child(st ?? "")))
        .child(h_flex().h(18).gap(8).items_center().min_w(0)
          .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(info.join(" · ")))
          .when(Boolean(chip), (el) => el.child(chip))
          .when(Boolean(pic), (el) => el.child(pic)));
    };
    const asleepRow = (r, on) => {
      const pic = icon(r.program, 14, t.muted), waking = this.reviving.has(r.address);
      return h_flex().id(`hib-${r.address}`).h(ASLEEP - 2).px(8).gap(8).items_center().rounded(6)
        .when(!waking, (el) => el.cursor_pointer()).when(on, (el) => el.bg(t.selected)).hover((s) => s.bg(on ? t.selected : t.hover))
        .role("button").accessibility_label(waking ? `Reviving ${r.title}` : `Revive ${r.title}`)
        .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(r.title))
        .child(waking
          ? h_flex().flex_none().gap(4).items_center().text_size(11).text_color(t.muted)
            .child(svg("mods/workspace-chrome/spinner.svg").size(11).flex_none().text_color(t.muted).spin(900)).child("Reviving…")
          : h_flex().flex_none().gap(4).items_center().text_size(11).text_color(t.dim)
            .child(svg("mods/tui-focus/moon.svg").size(11).flex_none().text_color(t.dim)).child(ago(r.at, now)))
        .when(Boolean(pic), (el) => el.child(pic));
    };
    // The keys, under the rows: a cap per key, p's lit while the picked row has a PR to open.
    const cap = (key, lit) => div().px(4).rounded(3).text_size(10).bg(lit ? t.accent : t.raised).text_color(lit ? t.background : t.muted).child(key);
    const hint = (keys, label, lit = false) => h_flex().flex_none().gap(3).items_center().text_color(lit ? t.foreground : t.dim)
      .children(keys.map((x) => cap(x, lit))).child(label);
    const footer = h_flex().flex_none().h(FOOT - 2).mt(2).pt(3).px(8).gap(10).items_center().border_t(1).border_color(t.border).text_size(11)
      .child(hint(["j", "k"], "move")).child(hint(["↵"], "peek")).child(hint(["p"], "open PR", Boolean(items[this.at]?.pr)))
      .child(hint(["esc"], "close"));
    return v_flex().id("subagents-root").track_focus(this.keys).size_full().p(6).text_size(13).bg(t.popover)
      .on_key_down((e, cx) => {
        const plain = !e.modifiers.control && !e.modifiers.alt && !e.modifiers.platform;
        if (e.key === "escape") closeOverlay(overlay);
        else if (e.key === "down" || (plain && e.key === "j")) step(1);
        else if (e.key === "up" || (plain && e.key === "k")) step(-1);
        else if (e.key === "enter" && items[this.at]) choose(items[this.at], cx);
        else if (plain && e.key === "p") openPr(items[this.at]?.pr);
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .when(items.length === 0, (el) => el.child(div().p(8).text_color(t.dim).child(filter ? "No agents." : "No workers.")))
      // A popup takes its content's height and a virtual list has none of its own: state it, capped as openers
      // cap the popup (360 less the 12px padding and the footer).
      .when(items.length > 0, (el) => el.child(div().relative().flex_none().h(Math.min(348 - FOOT, items.reduce((s, x) => s + x.h, 0)))
        .child(v_virtual_list("subagents-rows", items.length, items.map((x) => x.h), (i) => items[i].key,
          (range) => items.slice(range.start, range.end).map((x, j) => {
            const on = range.start + j === this.at;
            return div().h(x.h).pb(2).child(x.live ? liveRow(x.live, on, x.pr) : asleepRow(x.asleep, on));
          })).track_scroll(this.scroll).size_full()
          .on_item_click((key, cx) => {
            const i = items.findIndex((x) => x.key === key);
            if (i < 0) return;
            this.at = i;
            choose(items[i], cx);
            cx.notify();
          }))
        .child(Scrollbar.vertical("subagents-rows").absolute().inset_0()))
        .child(footer));
  }
}
