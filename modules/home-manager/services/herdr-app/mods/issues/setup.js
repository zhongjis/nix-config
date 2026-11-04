// Connecting a provider the first time, and the settings behind the gear.
import { div } from "gpui-kit";
import { h_flex, v_flex, Input, InputState } from "gpui-base";
import { icon, heading, primary, ghost, words } from "./look.js";
import { defaults } from "./logic.js";
import { publish } from "./shared.js";

const ADDRESS = /^https?:\/\/[^\s/?#@]+(?::\d+)?(?:\/[^\s?#]*)?$/;

const input = (o, state) => h_flex().h(36).flex_none().px(12).items_center().rounded(8).border_1().border_color(o.line).bg(o.sunk)
  .child(Input.new(state).flex_1().h_full().text_size(13).text_color(o.fg));

const row = (o, label, kid) => h_flex().w_full().gap(12).items_center()
  .child(div().flex_none().w(116).text_size(12.5).text_color(o.muted).child(label))
  .child(kid.flex_1().min_w(0));

// Where the token comes from, in words: `$NAME` for `printenv NAME`.
const source = (state) => {
  const name = /^printenv\s+(\w+)$/.exec(state.value().trim())?.[1];
  return name ? `$${name}` : "your token command";
};

// The settings' fields, filled from the saved ones; Enter in any saves.
export function fields(app) {
  const { jira, linear } = app.config;
  const out = {
    url: InputState.new({ placeholder: "https://jira.example.com", value: jira.url }),
    jql: InputState.new({ placeholder: defaults.jira.jql, value: jira.jql }),
    jiraToken: InputState.new({ placeholder: defaults.jira.tokenCommand, value: jira.tokenCommand }),
    linearToken: InputState.new({ placeholder: defaults.linear.tokenCommand, value: linear.tokenCommand }),
  };
  for (const field of Object.values(out)) field.on("submit", (_e, cx) => save(app, cx));
  return out;
}

export function openSettings(app, cx) {
  const { jira, linear } = app.config;
  app.fields.url.set_value(jira.url);
  app.fields.jql.set_value(jira.jql);
  app.fields.jiraToken.set_value(jira.tokenCommand);
  app.fields.linearToken.set_value(linear.tokenCommand);
  app.linearEnabled = linear.enabled;
  app.error = "";
  app.go("settings", cx);
}

export function save(app, cx) {
  const f = app.fields;
  const connecting = app.page === "connect" ? app.connecting : null;
  const url = f.url.value().trim().replace(/\/+$/, "");
  if (connecting === "jira" && !url) return app.say("Enter your Jira address, for example https://jira.example.com.", cx, true);
  if (url && !ADDRESS.test(url)) return app.say("Enter the address as https://host, without a query, fragment or credentials.", cx, true);
  const next = {
    jira: { url, jql: f.jql.value().trim() || defaults.jira.jql, tokenCommand: f.jiraToken.value().trim() || defaults.jira.tokenCommand },
    linear: { enabled: connecting === "linear" || app.linearEnabled, tokenCommand: f.linearToken.value().trim() || defaults.linear.tokenCommand },
  };
  for (const p of ["jira", "linear"]) if (JSON.stringify(next[p]) !== JSON.stringify(app.config[p])) delete app.cache[p];
  if (!app.cache.jira) app.jiraItems = [];
  app.config = next;
  app.linearEnabled = next.linear.enabled;
  localStorage.setItem("settings", JSON.stringify(next));
  localStorage.setItem("cache", JSON.stringify(app.cache));
  const configured = app.configured();
  app.error = "";
  if (!configured.length) {
    publish(app);
    return app.go("connect", cx);
  }
  app.switchProvider(connecting ?? (configured.includes(app.provider) ? app.provider : configured[0]), cx);
}

// Not set up yet: one field and Connect; the rest prefilled, under Advanced.
export function connect(app, o) {
  const jira = app.connecting === "jira";
  const other = jira ? "linear" : "jira";
  return v_flex().flex_none().w_full().max_w(640).gap(12).px(14).py(18).items_start()
    .child(div().text_size(15).font_semibold().text_color(o.fg).child(jira ? "Connect Jira" : "Connect Linear"))
    .child(div().text_size(13).text_color(o.muted).line_height(1.5).child(jira
      ? `Your Jira Data Center address. The token comes from ${source(app.fields.jiraToken)} when you connect and stays in memory.`
      : `Experimental. Uses a personal API key from ${source(app.fields.linearToken)}, read when you connect and kept in memory.`))
    .child(h_flex().w_full().gap(8).items_center()
      .child(input(o, jira ? app.fields.url : app.fields.linearToken).flex_1().min_w(0))
      .child(primary(o, "connect", "Connect", (cx) => save(app, cx)).h(36)))
    .when(Boolean(app.error), (el) => el.child(div().text_size(12.5).text_color(o.fix).child(app.error)))
    .when(jira, (el) => el.child(h_flex().id("advanced").flex_none().h(24).gap(4).items_center().cursor_pointer()
      .on_click((_e, cx) => { app.advanced = !app.advanced; cx.notify(); })
      .child(icon(app.advanced ? "chevron" : "chevron-right", o.muted, 13))
      .child(div().text_size(12.5).text_color(o.muted).hover((s) => s.text_color(o.fg)).child("Advanced"))))
    .when(jira && app.advanced, (el) => el.child(v_flex().w_full().gap(8).pl(17)
      .child(row(o, "My issues JQL", input(o, app.fields.jql)))
      .child(row(o, "Token command", input(o, app.fields.jiraToken)))))
    .child(words(o, [[[jira ? "or connect Linear (experimental)" : "or connect Jira", o.accent, (cx) => {
      app.connecting = other;
      app.error = "";
      app.go("connect", cx);
    }]]], "connect-other"));
}

function toggle(app, o) {
  const on = app.linearEnabled;
  return h_flex().id("linear-enabled").flex_none().h(24).gap(8).items_center().cursor_pointer()
    .on_click((_e, cx) => { app.linearEnabled = !on; cx.notify(); })
    .child(div().flex_none().w(16).h(16).rounded(4).border_1().border_color(on ? o.accent : o.line).bg(on ? o.accent : o.sunk)
      .flex().items_center().justify_center().when(on, (el) => el.child(icon("check", o.ink, 12))))
    .child(div().text_size(13).text_color(o.fg).child("Show Linear issues"));
}

export function settings(app, o) {
  const f = app.fields;
  return v_flex().id("issue-settings").flex_none().w_full().max_w(720).gap(10)
    .when(app.configured().length > 0, (el) => el.child(h_flex().id("back").flex_none().h(24).px(8).gap(4).items_center().rounded(6)
      .cursor_pointer().hover((s) => s.bg(o.raised)).on_click((_e, cx) => app.back(cx))
      .child(icon("back", o.muted, 13)).child(div().text_size(12).text_color(o.muted).child("Issues"))))
    .child(heading(o, "Jira", o.muted, null).px(0))
    .child(row(o, "Address", input(o, f.url)))
    .child(row(o, "My issues JQL", input(o, f.jql)))
    .child(row(o, "Token command", input(o, f.jiraToken)))
    .child(heading(o, "Linear · experimental", o.muted, null).px(0))
    .child(row(o, "", toggle(app, o)))
    .when(app.linearEnabled, (el) => el.child(row(o, "Token command", input(o, f.linearToken))))
    .child(div().pl(128).text_size(12).text_color(o.muted).line_height(1.5)
      .child("Commands run with zsh -c and print the token on one line. Only the commands are saved; tokens stay in memory."))
    .when(Boolean(app.error), (el) => el.child(div().pl(128).text_size(12.5).text_color(o.fix).child(app.error)))
    .child(h_flex().pl(128).pt(4).gap(8)
      .child(primary(o, "save", "Save", (cx) => save(app, cx)))
      .when(app.configured().length > 0, (el) => el.child(ghost(o, "cancel", "Cancel", (cx) => app.back(cx)))));
}
