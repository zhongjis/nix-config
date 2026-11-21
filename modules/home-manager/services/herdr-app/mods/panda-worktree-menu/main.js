// The right-click menu of every worktree row in panda-spaces. Without a space: open it as one, copy its path, remove
// it. With a space open there: rename or close the space, copy the path, remove the worktree (then the space closes).
// Opened as a popup with props { folder, branch, machine, repo, common, space }: `repo` is panda-spaces' group key,
// `common` the git common dir git runs in, `space` the open space's id or null. Looks as Herdr's `menu` does, but
// nothing is selected until an arrow key is pressed. Remove asks first, in place, naming what goes: uncommitted
// changes (then git gets --force) and the space's terminals. Any other refusal (a locked worktree, submodules) shows
// git's own words, and the space stays open.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { props, run, exec, notify, closeOverlay, setShared, theme, panes, agents, spaces } from "herdr";

const base = (path) => path.replace(/\/+$/, "").split("/").pop();
const COPY = ["Copy path", "mods/filetree/copy.svg", "copy"];
const REMOVE = ["Remove worktree…", "mods/workspace-chrome/x.svg", "remove"];
// The ones that end something (close, remove) sit last, after a divider.
const items = (p) => p?.space
  ? [["Rename space", "mods/workspace-chrome/square-pen.svg", "rename"], COPY, ["Close space", "mods/workspace-chrome/x.svg", "close"], REMOVE]
  : [["Open as space", "mods/workspace-chrome/folder.svg", "open"], COPY, REMOVE];
const ENDS = new Set(["close", "remove"]);

// What closing the space ends: its terminals, and of those the agents working.
function inSpace(id) {
  const s = spaces().find((x) => x.id === id);
  const tabs = new Set((s?.tabs ?? []).map((t) => t.id));
  return { terminals: panes().filter((p) => tabs.has(p.tab) && p.terminal).length, working: agents().filter((a) => a.space === id && a.status === "working").length };
}
const plural = (n, word) => `${n} ${word}${n > 1 ? "s" : ""}`;

export default class WorktreeMenu extends View {
  init(_props, cx) {
    this.at = -1; // the keyboard's item; none until an arrow key
    this.asking = false; // the remove question is shown
    this.busy = false;
    this.error = null;
    this.dirty = null; // uncommitted changes in the worktree; null until counted
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  choose(i, cx) {
    const p = props();
    const it = items(p)[i];
    if (!it) return;
    if (it[2] === "rename" || it[2] === "close") {
      closeOverlay(p.overlay);
      run(`space.${it[2]}`, { id: p.space });
    } else if (it[2] === "open") {
      closeOverlay(p.overlay);
      run("space.new", { folder: p.folder, machine: p.machine ?? "" });
    } else if (it[2] === "copy") {
      cx.write_to_clipboard(p.folder);
      closeOverlay(p.overlay);
      notify({ title: "Path copied", body: p.folder, level: "success" });
    } else {
      this.asking = true;
      cx.notify();
      cx.spawn(async (cx) => {
        const r = await exec("git", ["status", "--porcelain"], { cwd: p.folder, on: p.machine }).catch(() => null);
        this.dirty = r?.code === 0 ? r.stdout.split("\n").filter(Boolean).length : 0;
        cx.notify();
      });
    }
  }

  remove(cx) {
    if (this.busy || this.dirty === null) return;
    const p = props();
    this.busy = true;
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      const r = await exec("git", ["worktree", "remove", ...(this.dirty ? ["--force"] : []), p.folder], { cwd: p.common, on: p.machine })
        .catch((e) => ({ code: 1, stderr: String(e?.message ?? e) }));
      if (r.code === 0) {
        // Removed first, closed after: a refusal leaves the space as it was.
        if (p.space && spaces().some((s) => s.id === p.space)) run("space.close", { id: p.space, confirmed: true });
        // panda-spaces looks at the repo's worktrees again at once.
        setShared("panda-spaces.stale", { repo: p.repo, at: Date.now() });
        closeOverlay(p.overlay);
        return;
      }
      this.busy = false;
      this.error = (r.stderr || r.stdout || "").trim().replace(/^fatal: /, "") || "Git couldn't remove the worktree.";
      cx.notify();
    });
  }

  question(t, p) {
    const button = (id, label, bg, fg, onClick) => h_flex().id(id).h(30).px(12).items_center().rounded(7).border_1()
      .border_color(id === "no" ? t.input : bg).bg(bg).text_color(fg)
      .when(!(id === "yes" && (this.busy || this.dirty === null)), (el) => el.cursor_pointer().hover((s) => s.opacity(0.88)).on_click(onClick))
      .when(id === "yes" && (this.busy || this.dirty === null), (el) => el.opacity(0.6))
      .child(label);
    const branch = p.branch ? `The branch ${p.branch} stays.` : "";
    const lost = this.dirty ? `Its ${this.dirty} uncommitted change${this.dirty > 1 ? "s are" : " is"} lost.` : "";
    const open = p.space ? inSpace(p.space) : null;
    const ends = open ? `Closes the space: ${plural(open.terminals, "terminal")} end${open.terminals === 1 ? "s" : ""}${open.working ? `, ${plural(open.working, "agent")} working` : ""}.` : "";
    const label = this.busy ? "Removing…" : this.dirty === null ? "Checking…" : this.dirty ? "Discard and remove" : "Remove";
    return v_flex().p(12).gap(10)
      .child(div().text_size(14).font_semibold().text_color(t.foreground).child("Remove worktree?"))
      .child(div().text_color(t.muted).child(`Deletes the folder ${base(p.folder)}. ${branch}`.trim()))
      .when(Boolean(ends), (el) => el.child(div().text_color(t.muted).child(ends)))
      .when(Boolean(lost), (el) => el.child(div().text_color(t.blocked).child(lost)))
      .when(Boolean(this.error), (el) => el.child(div().text_size(12).text_color(t.blocked).child(this.error)))
      .child(h_flex().justify_end().gap(8).text_size(12)
        .child(button("no", "Cancel", t.raised, t.foreground, () => closeOverlay(props().overlay)))
        .child(button("yes", label, t.blocked, t.solid_foreground, (_e, cx) => this.remove(cx))));
  }

  render(cx) {
    const t = theme();
    const p = props() ?? {};
    const list = items(p);
    return v_flex()
      .id("worktree-menu")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .on_key_down((e, cx) => {
        if (this.asking) {
          if (e.key === "enter") this.remove(cx);
          else return;
        } else if (e.key === "down") this.at = (this.at + 1) % list.length;
        else if (e.key === "up") this.at = this.at < 0 ? list.length - 1 : (this.at + list.length - 1) % list.length;
        else if (e.key === "enter") { if (this.at >= 0) this.choose(this.at, cx); }
        else return;
        cx.notify();
      })
      .when(this.asking, (el) => el.child(this.question(t, p)))
      .when(!this.asking, (el) => el.children(list.map(([label, icon, action], i) =>
        v_flex()
          .when(ENDS.has(action) && !ENDS.has(list[i - 1]?.[2]), (el) => el.child(div().mx(7).my(4).h(1).bg(t.border)))
          .child(h_flex().id(`wm-${action}`).h(31).px(8).gap(9).rounded(7).items_center().text_color(t.foreground)
            .when(i === this.at, (el) => el.bg(t.selected))
            .hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => this.choose(i, cx))
            .child(svg(icon).size(14).flex_none().text_color(t.muted))
            .child(div().flex_1().child(label))))));
  }
}
