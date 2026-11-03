// A popup listing an agent's live sub-agents (props().parent), all the way down; a click peeks at one.
// Opened from tui-focus cards' "N sub-agents working" line.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, terminals, theme, run, props, closeOverlay, exec } from "herdr";

const icon = (p, size, color) => !p?.icon ? null
  : p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();

// Live sub-agents of `addr`, depth first, with their depth.
const tree = (all, addr, depth = 0) => all.filter((k) => k.parent === addr && k.state === "live")
  .flatMap((k) => [{ k, depth }, ...tree(all, k.address, depth + 1)]);

const base = (path) => path.replace(/[\\/]+$/, "").split(/[\\/]/).pop() || path;

// Where a terminal works: its project (the main checkout's folder, so a worktree reads as its repo) and
// branch. Outside git: the folder's name, no branch. A terminal on another machine (`vps/t7`) runs git there.
async function place(k) {
  const on = k.address.includes("/") ? k.address.split("/")[0] : undefined;
  try {
    const r = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir", "--abbrev-ref", "HEAD"], { cwd: k.cwd, on });
    const [common, branch] = r.stdout.trim().split("\n");
    if (r.code === 0 && common) return { project: base(common.replace(/[\\/]\.git$/, "")), branch: branch && branch !== "HEAD" ? branch : null };
  } catch {}
  return { project: base(k.cwd), branch: null };
}

export default class SubAgents extends View {
  init(_props, cx) {
    // address → {project, branch}, for the parent and each sub-agent; re-read gently, as branches change.
    this.places = {};
    this.refresh(cx);
    cx.timer.every(5000, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      const parent = props()?.parent, all = terminals();
      const ks = [all.find((k) => k.address === parent), ...tree(all, parent).map((r) => r.k)].filter((k) => k?.cwd);
      for (const k of ks) this.places[k.address] = await place(k);
      cx.notify();
    });
  }

  render() {
    const t = theme(), { parent, overlay } = props() ?? {};
    // A sub-agent with a pane is in agents(); else its raw word, error counting as blocked.
    const listed = new Map(agents().map((a) => [a.address, a.status]));
    const word = (k) => { const s = listed.get(k.address) ?? k.status; return s === "error" ? "blocked" : s; };
    const color = { working: t.working, blocked: t.blocked, done: t.done, idle: t.idle };
    const rows = tree(terminals(), parent);
    const mine = this.places[parent] ?? {};
    return v_flex().id("subagents-root").size_full().p(6).gap(2).text_size(13).bg(t.popover).overflow_y_scrollbar()
      .when(rows.length === 0, (el) => el.child(div().p(8).text_color(t.dim).child("No live sub-agents.")))
      .children(rows.map(({ k, depth }) => {
        const st = word(k);
        // Second line: project and branch, each only when it differs from the parent's.
        const at = this.places[k.address] ?? {};
        const info = [at.project !== mine.project ? at.project : null, at.branch !== mine.branch ? at.branch : null].filter(Boolean);
        const pic = icon(k.program, 14, t.muted);
        // First line: name and status. Second: project/branch, and the agent icon on the right.
        return v_flex().id(`sub-${k.address}`).flex_none().py(5).pl(8 + depth * 16).pr(8).rounded(6)
          .cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click(() => { closeOverlay(overlay); run("terminal.peek", { terminal: k.address }); })
          .child(h_flex().h(20).gap(8).items_center().min_w(0)
            .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(k.name || k.template || k.program?.name || k.address))
            .child(div().flex_none().text_size(11).text_color(color[st] ?? t.dim).child(st ?? "")))
          .when(info.length > 0 || Boolean(pic), (el) => el.child(h_flex().h(18).gap(8).items_center().min_w(0)
            .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(info.join(" · ")))
            .when(Boolean(pic), (el) => el.child(pic))));
      }));
  }
}
