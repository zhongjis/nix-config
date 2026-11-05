// An issue's screen, as herdr-linear's: where it is, its title and facts,
// then its description and comments, and a comment box when asked for.
import { div } from "gpui-kit";
import { h_flex, v_flex, Textarea, TextView } from "gpui-base";
import { icon, stateIcon, stateColor, stateHue, priorityIcon, chip, heading, primary, ghost, ago, tint, MONO } from "./look.js";
import { jiraMarkdown } from "./logic.js";
import { statuses, comment } from "./actions.js";

const field = (o, label, kids) => h_flex().flex_none().gap(10).items_center().min_h(24)
  .child(div().flex_none().w(72).text_size(12).text_color(o.muted).child(label))
  .child(h_flex().flex_1().min_w(0).gap(6).flex_wrap().items_center().children([kids].flat().filter(Boolean)));

function text(app, o, id, value) {
  return TextView.markdown(id, app.provider === "jira" ? jiraMarkdown(value) : value).selectable(true).text_size(13).text_color(o.muted).on_link_click((url, cx) => cx.open_url(url));
}

function facts(o, is) {
  const prio = priorityIcon(is.level);
  return v_flex().flex_none().gap(4)
    .child(field(o, "Assignee", is.assignee
      ? [icon("person", o.dim, 13), div().text_color(o.fg).child(is.assignee)]
      : div().text_color(o.dim).child("Unassigned")))
    .when(Boolean(is.priority), (el) => el.child(field(o, "Priority", [prio ? icon(prio, is.level === 1 ? o.fix : o.muted, 13) : null, div().text_color(o.fg).child(is.priority)])))
    .when(Boolean(is.project), (el) => el.child(field(o, "Project", [chip(o, "project", [icon("project", o.dim, 12), is.project]), is.type ? div().text_color(o.muted).child(is.type) : null])))
    .when(is.labels.length > 0, (el) => el.child(field(o, "Labels", is.labels.map((l, i) => chip(o, `label-${i}`, [l])))))
    .when(is.links.length > 0, (el) => el.child(field(o, "Links", is.links.map((l, i) =>
      chip(o, `link-${i}`, [l.title.length > 56 ? `${l.title.slice(0, 55)}…` : l.title], { color: o.accent, click: (cx) => cx.open_url(l.url) })))))
    .when(Boolean(is.updated), (el) => el.child(field(o, "Updated", div().text_color(o.muted).child(ago(Date.parse(is.updated))))));
}

function comments(app, o) {
  const list = app.comments;
  return v_flex().flex_none().gap(12).pt(6)
    .child(heading(o, "Comments", null, list ? list.length : "…").px(0))
    .when(Boolean(list) && !list.length, (el) => el.child(div().text_size(12).text_color(o.dim).child("No comments yet · press A to add one")))
    .children((list ?? []).map((c) => v_flex().gap(4)
      .child(h_flex().gap(8).items_center()
        .child(icon("person", o.dim, 12))
        .child(div().text_size(12).font_medium().text_color(o.fg).child(c.author))
        .child(div().text_size(12).text_color(o.dim).child(ago(Date.parse(c.created)))))
      .child(div().pl(20).child(text(app, o, `comment-${c.id}`, c.body)))));
}

function composer(app, o) {
  return v_flex().flex_none().gap(8)
    .child(Textarea.new(app.draft).h(88).p(8).rounded(8).border_1().border_color(o.line).bg(o.sunk).text_size(13).text_color(o.fg))
    .child(h_flex().gap(8).items_center()
      .child(div().flex_1().text_size(12).text_color(o.muted).child(`${app.api.syntax}, sent as typed`))
      .child(ghost(o, "cancel-comment", "Cancel", (cx) => app.escape(cx)))
      .child(primary(o, "send-comment", "Comment", (cx) => comment(app, cx))));
}

export function detail(app, o) {
  const is = app.issue;
  const d = app.detail;
  const failed = !d && Boolean(app.error);
  return v_flex().flex_1().min_h(0).gap(10)
    .child(h_flex().flex_none().gap(10).items_center()
      .child(h_flex().id("back").flex_none().h(22).px(6).gap(2).items_center().rounded(5).cursor_pointer().hover((s) => s.bg(o.hover))
        .on_click((_e, cx) => app.back(cx))
        .child(icon("back", o.muted, 14))
        .child(div().text_size(12).text_color(o.muted).child(app.tab === "recent" ? "Recent" : "My issues")))
      .when(Boolean(is?.state), (el) => el.child(chip(o, "status", [icon(stateIcon(is.state), stateHue(o, is.state), 12), is.state.name, d ? icon("chevron", stateColor(o, is.state), 11) : null],
        { color: stateColor(o, is.state), click: (cx) => statuses(app, cx) })))
      .child(div().font_family(MONO).text_size(12).text_color(o.muted).child(is?.identifier ?? app.key))
      .child(div().text_size(12).text_color(o.dim).child(app.api.where)))
    .when(Boolean(is), (el) => el.child(div().flex_none().text_size(17).font_semibold().text_color(o.fg).line_height(1.35).child(is.title)))
    .when(Boolean(d), (el) => el.child(facts(o, d)))
    .when(failed, (el) => el.child(v_flex().flex_none().gap(8).px(14).py(12).rounded(8).bg(tint(o.fix, 0.1))
      .child(div().text_size(13).font_semibold().text_color(o.fg).child(`Couldn't load ${app.key}`))
      .child(div().text_size(12).text_color(o.fg).child(app.error))
      .child(h_flex().gap(8).pt(2).child(primary(o, "retry-issue", "Retry", (cx) => app.open(app.key, cx))))))
    .child(div().flex_none().h(1).bg(o.line))
    .child(v_flex().id("issue-body").h(app.composing ? 250 : 360).min_h(0).flex_shrink(1).overflow_y_scrollbar().pr(6).gap(10)
      .child(d ? text(app, o, `desc-${d.id}`, d.description || "_No description._")
        : div().text_size(12).text_color(o.dim).child(failed ? "" : "Loading…"))
      .when(Boolean(d), (el) => el.child(comments(app, o))))
    .when(app.composing, (el) => el.child(composer(app, o)));
}
