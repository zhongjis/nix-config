// The list: a filter that also finds any issue by its key, the tabs, and the
// issues by status, as herdr-linear draws them.
import { div } from "gpui-kit";
import { h_flex, v_flex, Input, v_virtual_list, Scrollbar } from "gpui-base";
import { icon, stateIcon, stateColor, priorityIcon, countPill, heading, primary, ghost, tint, MONO } from "./look.js";
import { byStatus, matches, KEY } from "./logic.js";
import { openSettings } from "./setup.js";

const HEADING_H = 30;
const ROW_H = 36;
const LIST_H = 560;
const TABS = [
  { id: "mine", label: "My issues", short: "Mine", icon: "person" },
  { id: "recent", label: "Recent", icon: "calendar" },
];

// The rows shown, in order: My issues by status, then a key looked up that
// isn't among them; Recent as last opened.
export function shown(app) {
  const filter = app.input.value();
  if (app.tab === "recent") return (app.recent[app.provider] ?? []).filter((i) => matches(i, filter)).map((issue) => ({ issue, group: null, state: null }));
  const rows = byStatus(app.items.filter((i) => matches(i, filter)))
    .flatMap((g) => g.issues.map((issue) => ({ issue, group: g.name, state: g.state })));
  if (app.found && !rows.some((r) => r.issue.identifier === app.found.identifier)) rows.push({ issue: app.found, group: "Not in your issues", state: null });
  return rows;
}

export function search(app, o) {
  return h_flex().h(36).flex_none().px(12).gap(10).items_center().rounded(9).border_1().border_color(o.line).bg(o.sunk)
    .child(icon("search", o.dim, 15))
    .child(Input.new(app.input).flex_1().h_full().text_size(13).text_color(o.fg))
    .child(div().flex_none().text_size(12).text_color(o.muted).child(app.api.where));
}

export function tabs(app, o) {
  const many = app.configured().length > 1;
  return h_flex().flex_none().gap(4).items_center()
    .children(TABS.map((tb) => {
      const on = tb.id === app.tab;
      const n = tb.id === "mine" ? (app.loaded ? app.items.length : null) : (app.recent[app.provider] ?? []).length;
      return h_flex().id(`tab-${tb.id}`).flex_none().h(28).px(10).gap(7).items_center().rounded(7).cursor_pointer().text_size(12.5)
        .when(on, (el) => el.bg(o.raised).shadow_sm())
        .when(!on, (el) => el.hover((s) => s.bg(o.hover)))
        .on_click((_e, cx) => { if (!on) app.step(cx); })
        // The spinner in its icon's place while it loads, so the tabs never move.
        .child(tb.id === "mine" && app.loading ? icon("work", o.accent, 12).spin(1100) : icon(tb.icon, on ? o.fg : o.dim, 12))
        .child(div().when(on, (el) => el.font_semibold()).when(!on, (el) => el.font_medium()).text_color(on ? o.fg : o.muted)
          .child(app.width < 700 ? tb.short ?? tb.label : tb.label))
        .child(countPill(o, n, on));
    }))
    .child(div().flex_1())
    // The provider, as herdr-linear's workspace: with both, a click (or ⌃T) goes to the other.
    .child(h_flex().id("provider").flex_none().h(26).px(8).gap(6).items_center().rounded(6).border_1().border_color(o.line)
      .when(many, (el) => el.cursor_pointer().hover((s) => s.bg(o.hover)).on_click((_e, cx) => app.switchProvider(app.provider === "jira" ? "linear" : "jira", cx)))
      .child(div().text_size(12).text_color(o.muted).child(app.api.label))
      .when(many, (el) => el.child(div().font_family(MONO).text_size(11).text_color(o.dim).child(`${app.configured().indexOf(app.provider) + 1}/2`))))
    .child(h_flex().id("settings").flex_none().w(26).h(26).items_center().justify_center().rounded(6).border_1().border_color(o.line)
      .cursor_pointer().hover((s) => s.bg(o.hover)).on_click((_e, cx) => openSettings(app, cx))
      .child(icon("settings", o.muted, 14)));
}

// An issue's row, one line: its status's icon and colour, key and title;
// then, quietly, its project and type, and its priority at the end. The
// chosen one lifts, with an edge in its status's colour.
function row(app, o, issue, on, keyW) {
  const color = stateColor(o, issue.state);
  const prio = priorityIcon(issue.level);
  const wide = app.width >= 760;
  return h_flex().id(`is-${issue.identifier}`).flex_none().h(34).pl(10).pr(12).gap(10).items_center().rounded(7).cursor_pointer()
    .when(on, (el) => el.bg(o.raised).shadow_sm())
    .when(!on, (el) => el.hover((s) => s.bg(o.raised)))
    .child(div().flex_none().w(3).h(16).rounded(2).when(on, (el) => el.bg(color)))
    .child(icon(stateIcon(issue.state), color, 14))
    .child(div().flex_none().w(keyW).font_family(MONO).text_size(11.5).text_color(o.muted).truncate().child(issue.identifier))
    .child(div().flex_1().min_w(0).truncate().text_size(13.5).when(on, (el) => el.font_medium()).text_color(o.fg).child(issue.title))
    .when(wide, (el) => el.child(div().flex_none().w(170).truncate().text_size(12).text_color(o.dim).child(issue.project)))
    .when(wide && app.provider === "jira", (el) => el.child(div().flex_none().w(84).truncate().text_size(12).text_color(o.dim).child(issue.type)))
    .child(div().flex_none().w(14).child(prio ? icon(prio, issue.level === 1 ? o.fix : o.muted, 13) : div()));
}

const note = (o, text) => div().px(14).py(10).text_size(12.8).text_color(o.muted).child(text);

function failure(app, o) {
  return v_flex().flex_none().gap(8).px(14).py(12).rounded(8).bg(tint(o.fix, 0.1))
    .child(h_flex().gap(8).items_center()
      .child(icon("need", o.fix, 14))
      .child(div().text_size(13).font_semibold().text_color(o.fg).child(`Couldn't load your ${app.api.label} issues`)))
    .child(div().text_size(12.5).text_color(o.fg).child(app.listError))
    .child(h_flex().gap(8).pt(2)
      .child(primary(o, "retry", "Retry", (cx) => app.load(cx)))
      .child(ghost(o, "fix-settings", "Settings", (cx) => openSettings(app, cx), "settings")));
}

// Rows the shape of the ones coming, while the first list loads.
const skeleton = (o, i) => {
  const bar = tint(o.muted, 0.2);
  return h_flex().flex_none().h(34).pl(23).pr(12).gap(10).items_center()
    .loop("opacity", { from: 0.5, to: 1, period: 1400 })
    .child(div().flex_none().w(14).h(14).rounded_full().bg(bar))
    .child(div().flex_none().w(64).h(9).rounded(3).bg(bar))
    .child(div().flex_none().w([320, 240, 400, 280, 200][i]).h(9).rounded(3).bg(bar));
};

function empty(app, o) {
  if (app.tab === "recent") return note(o, app.input.value() ? "Nothing you opened lately matches." : "Issues you open here are kept here, newest first.");
  if (app.input.value()) return note(o, "Nothing matches. Type a whole key (ABC-123) to look it up beyond your issues.");
  return note(o, app.provider === "jira" ? "No issues match your JQL. Change it in Settings." : "No open issues assigned to you.");
}

export function list(app, o) {
  const rows = app.shown;
  const keyW = Math.min(120, Math.max(64, Math.ceil(Math.max(0, ...rows.map((r) => r.issue.identifier.length)) * 7.2)));
  const entries = [];
  app.entryOf = [];
  let last = null;
  rows.forEach((r, i) => {
    if (r.group && r.group !== last) {
      const n = rows.filter((x) => x.group === r.group).length;
      entries.push({ key: `h-${r.group}`, h: HEADING_H, el: () => heading(o, r.group, r.state ? stateColor(o, r.state) : null, n) });
    }
    last = r.group;
    app.entryOf[i] = entries.length;
    entries.push({ key: `r-${r.issue.identifier}`, row: i, h: ROW_H, el: () => div().h(ROW_H).pb(2).child(row(app, o, r.issue, i === app.at, keyW)) });
  });
  const mine = app.tab === "mine";
  return v_flex().flex_1().min_h(0).gap(2)
    .when(mine && Boolean(app.listError), (el) => el.child(failure(app, o)))
    .when(mine && !rows.length && app.loading && !app.loaded, (el) => el.children([0, 1, 2, 3, 4].map((i) => skeleton(o, i))))
    .when(!rows.length && !(mine && (app.listError || (app.loading && !app.loaded))), (el) => el.child(empty(app, o)))
    .when(entries.length > 0, (el) => el.child(
      div().relative().h(Math.min(LIST_H, entries.reduce((h, e) => h + e.h, 0))).min_h(0).flex_shrink(1)
        .child(v_virtual_list("issue-rows", entries.length, entries.map((e) => e.h), (i) => entries[i].key,
          (range) => entries.slice(range.start, range.end).map((e) => e.el())).track_scroll(app.scroll).size_full()
          // A click chooses a row; on the chosen one, opens it.
          .on_item_click((key, cx) => {
            const e = entries.find((x) => x.key === key);
            if (e?.row == null) return;
            if (e.row === app.at) return app.enter(cx);
            app.at = e.row;
            cx.notify();
          }))
        .child(Scrollbar.vertical("issue-rows").absolute().inset_0())));
}

// An issue's key in the filter: looked up beyond your issues, shortly after
// typing stops.
export function lookUp(app, cx) {
  const q = app.input.value().trim();
  app.found = null;
  if (app.tab !== "mine" || !KEY.test(q)) return;
  const api = app.api;
  cx.timer.after(300, (cx) => {
    if (app.input.value().trim() !== q) return;
    cx.spawn(async (cx) => {
      try {
        const issue = await api.get(q.toUpperCase());
        if (app.input.value().trim() === q) app.found = issue;
      } catch {
        // Best effort: Enter still opens the key and shows why it failed.
      }
      cx.notify();
    });
  });
}

// Keeps the chosen row in sight: the first, with its heading.
export function follow(app) {
  const e = app.entryOf?.[app.at];
  if (e != null) app.scroll.scroll_to_item(app.at === 0 ? 0 : e);
}
