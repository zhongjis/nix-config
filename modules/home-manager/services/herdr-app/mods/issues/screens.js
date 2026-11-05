// The popup: the screen shown, a status line, and its keys along the bottom,
// each also a click.
import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme } from "herdr";
import { tones, tint, icon, stateIcon, stateHue, key, MONO } from "./look.js";
import { search, tabs, list, follow } from "./list.js";
import { detail } from "./detail.js";
import { connect, settings, openSettings, save } from "./setup.js";
import { compose, statuses, move, comment } from "./actions.js";

const other = (app) => (app.provider === "jira" ? "linear" : "jira");

function listKey(app, k, cx) {
  const n = app.shown.length;
  const row = app.shown[app.at];
  if (k === "down" && n) app.at = Math.min(n - 1, app.at + 1);
  else if (k === "up" && n) app.at = Math.max(0, app.at - 1);
  else if (k === "pagedown" && n) app.at = Math.min(n - 1, app.at + 12);
  else if (k === "pageup" && n) app.at = Math.max(0, app.at - 12);
  else if ((k === "left" || k === "right") && !app.input.value()) app.step(cx);
  else if (k === "ctrl-o" && row) cx.open_url(row.issue.url);
  else if (k === "ctrl-r") app.load(cx);
  else if (k === "ctrl-t" && app.configured().length > 1) app.switchProvider(other(app), cx);
  else if (k === "ctrl-,") openSettings(app, cx);
  else return false;
  follow(app);
  return true;
}

function detailKey(app, k, cx) {
  if (app.editing) {
    if (k !== "cmd-enter" && k !== "ctrl-enter") return false;
    comment(app, cx);
    return true;
  }
  const is = app.detail;
  if (k === "left" || k === "backspace") app.back(cx);
  else if (k === "r") app.reload(cx);
  else if (!is) return false;
  else if (k === "c") statuses(app, cx);
  else if (k === "a") compose(app, cx);
  else if (k === "o") cx.open_url(is.url);
  else if (k === "y") app.copy(is.identifier, cx);
  else if (k === "b") app.copy(is.url, cx);
  else return false;
  return true;
}

function menuKey(app, k, cx) {
  const m = app.menu;
  const n = m.items.length;
  if (k === "down" && n) m.at = (m.at + 1) % n;
  else if (k === "up" && n) m.at = (m.at + n - 1) % n;
  else if (k === "enter" && n) move(app, m.items[m.at], cx);
  else if (/^[1-9]$/.test(k) && Number(k) <= n) move(app, m.items[Number(k) - 1], cx);
  else return false;
  return true;
}

function keyboard(app, e, cx) {
  const k = e.keystroke;
  if (k === "escape") app.escape(cx);
  else if (app.menu) { if (!menuKey(app, k, cx)) return; }
  else if (app.page === "list") { if (!listKey(app, k, cx)) return; }
  else if (app.page === "detail") { if (!detailKey(app, k, cx)) return; }
  else if (k === "enter") save(app, cx);
  else return;
  cx.stop_propagation();
  cx.notify();
}

function menu(app, o) {
  const m = app.menu;
  return v_flex().flex_none().gap(2).p(10).rounded(10).border_1().border_color(o.line).bg(o.raised).shadow_md()
    .child(div().px(6).pb(6).text_size(13).font_semibold().text_color(o.fg).child(m.items.length ? m.title : "No status changes are available."))
    .children(m.items.map((it, i) => {
      const on = i === m.at;
      return h_flex().id(`move-${i}`).h(30).px(8).gap(10).items_center().rounded(6).cursor_pointer()
        .when(on, (el) => el.bg(tint(o.accent, 0.18)))
        .when(!on, (el) => el.hover((s) => s.bg(o.sunk)))
        .on_click((_e, cx) => move(app, it, cx))
        .child(div().flex_none().w(14).font_family(MONO).text_size(11).text_color(o.dim).child(i < 9 ? String(i + 1) : ""))
        .child(icon(stateIcon(it.state), stateHue(o, it.state), 13))
        .child(div().text_size(13).when(on, (el) => el.font_medium()).text_color(on ? o.fg : o.muted).child(it.name))
        .when(it.state.name !== it.name, (el) => el.child(div().text_size(12).text_color(o.dim).child(`→ ${it.state.name}`)));
    }));
}

function footer(app, o) {
  const k = (keys, label, fn, id) => key(o, keys, label, fn, id);
  const esc = (label) => k(["esc"], label, (cx) => app.escape(cx), "f-esc");
  const is = app.detail;
  const row = app.shown[app.at];
  if (app.menu) return [k(["↑", "↓"], "choose", null, "f-choose"), k(["enter"], "move", (cx) => app.menu.items.length && move(app, app.menu.items[app.menu.at], cx), "f-move"), esc("cancel")];
  if (app.page === "detail" && app.composing) return [k(["cmd-enter"], "comment", (cx) => comment(app, cx), "f-send"), esc("cancel")];
  if (app.page === "detail") {
    return is ? [
      k(["c"], "status", (cx) => statuses(app, cx), "f-c"), k(["a"], "comment", (cx) => compose(app, cx), "f-a"),
      k(["o"], app.api.label, (cx) => cx.open_url(is.url), "f-o"), k(["y"], "copy key", (cx) => app.copy(is.identifier, cx), "f-y"),
      k(["b"], "copy link", (cx) => app.copy(is.url, cx), "f-b"), esc("back"),
    ] : [k(["r"], "retry", (cx) => app.reload(cx), "f-r"), esc("back")];
  }
  if (app.page === "connect") return [k(["enter"], "connect", (cx) => save(app, cx), "f-go"), esc("close")];
  if (app.page === "settings") return [k(["enter"], "save", (cx) => save(app, cx), "f-go"), esc(app.configured().length ? "back" : "close")];
  return [
    k(["↑", "↓"], "choose", null, "f-choose"),
    k(["enter"], "open", (cx) => app.enter(cx), "f-open"),
    k(["^o"], app.api.label, (cx) => row && cx.open_url(row.issue.url), "f-o"),
    k(["^r"], "refresh", (cx) => app.load(cx), "f-r"),
    ...(app.configured().length > 1 ? [k(["^t"], other(app) === "jira" ? "Jira" : "Linear", (cx) => app.switchProvider(other(app), cx), "f-t")] : []),
    k(["←", "→"], "tabs", (cx) => app.step(cx), "f-tabs"),
    k(["^,"], "settings", (cx) => openSettings(app, cx), "f-settings"),
    esc("close"),
  ];
}

// The status line: what's under way, what went wrong, what was done. A list
// that failed to load, and an issue that did, say so in place instead.
function note(app, o) {
  const inPlace = app.page === "connect" || app.page === "settings" || (app.page === "detail" && !app.detail);
  const error = inPlace ? "" : app.error;
  const text = app.busy || error || app.flash;
  if (!text) return null;
  return h_flex().flex_none().gap(8).items_center()
    .when(Boolean(app.busy), (el) => el.child(icon("work", o.accent, 12).spin(1100)))
    .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(app.busy ? o.accent : error ? o.fix : o.muted).child(text));
}

export function screen(app, _cx) {
  const o = tones(theme());
  const p = app.page;
  const status = note(app, o);
  if (p === "list") app.at = Math.max(0, Math.min(app.at, app.shown.length - 1));
  return v_flex().id("issues").w_full().min_h(0).p(16).gap(10).bg(o.surface).text_size(13)
    // The keyboard: the filter's in the list, so ↑ ↓ reach the list through
    // it; the fields' in a form; on an issue, the popup's own.
    .when(p === "detail", (el) => el.track_focus(app.keys))
    .on_size_change((size, cx) => {
      if (Math.abs(size.width - app.width) > 20) { app.width = size.width; cx.notify(); }
    })
    .on_key_down((e, cx) => keyboard(app, e, cx))
    .when(p === "list", (el) => el.child(search(app, o)).child(tabs(app, o)).child(list(app, o)))
    .when(p === "detail", (el) => el.child(detail(app, o)))
    .when(p === "connect", (el) => el.child(connect(app, o)))
    .when(p === "settings", (el) => el.child(settings(app, o)))
    .when(Boolean(app.menu), (el) => el.child(menu(app, o)))
    .when(Boolean(status), (el) => el.child(status))
    // The keys along the bottom, however tall the screen; each one's padding
    // hangs into the margin, so the first keycap lines up with the content.
    .child(div().flex_none().mt_auto().pt(8).border_t_1().border_color(o.line)
      .child(h_flex().ml(-6).gap(2).flex_wrap().items_center().children(footer(app, o))));
}
