// The popup's side of other mods: what it tells them (issues.refs), and an
// issue they ask it to open (issues.open).
import { shared, setShared } from "herdr";
import { projectKeys } from "./logic.js";

export function publish(app) {
  setShared("issues.refs", {
    jiraHost: app.config.jira.url.replace(/\/+$/, ""),
    projectKeys: projectKeys(app.config.jira.jql, app.jiraItems),
    linear: app.config.linear.enabled,
  });
}

// `issues.open` = {provider, key, at}: each request once.
export function takeOpen(app) {
  const open = shared("issues.open");
  if (!open || !(open.at > app.lastOpen)) return null;
  app.lastOpen = open.at;
  localStorage.setItem("lastOpen", String(open.at));
  return open;
}

export function handleOpen(app, open, cx) {
  if (!app.configured().includes(open.provider)) {
    app.connecting = open.provider === "linear" ? "linear" : "jira";
    app.error = `Connect ${open.provider === "linear" ? "Linear" : "Jira"} to open ${open.key}.`;
    return app.go("connect", cx);
  }
  if (open.provider !== app.provider) app.switchProvider(open.provider, cx);
  app.open(open.key, cx);
}
