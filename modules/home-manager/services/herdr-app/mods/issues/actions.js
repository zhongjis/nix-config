// Changing an issue: its status, and a comment on it. Each asks once at a
// time and reloads the issue after.

export function compose(app, cx) {
  if (!app.detail) return;
  app.composing = true;
  cx.timer.after(30, () => app.draft.focus());
  cx.notify();
}

// The provider's transitions from here, the current status chosen.
export function statuses(app, cx) {
  const issue = app.detail;
  if (app.busy || !issue) return;
  const api = app.api;
  app.task("Loading statuses…", async (_cx, generation) => {
    const items = await api.transitions(issue.identifier);
    if (generation !== app.generation) return;
    app.menu = { title: `Move ${issue.identifier} to`, items, at: Math.max(0, items.findIndex((t) => t.state.name === issue.state.name)) };
  }, cx);
}

export function move(app, item, cx) {
  const key = app.detail.identifier;
  const api = app.api;
  app.menu = null;
  app.task(`Moving ${key} to ${item.state.name}…`, async (cx, generation) => {
    await api.transition(key, item.id);
    if (generation === app.generation) { app.open(key, cx); app.load(cx); }
  }, cx);
}

// Sends the text exactly as typed.
export function comment(app, cx) {
  const text = app.draft.value();
  if (app.busy || !app.detail || !text.trim()) return;
  const key = app.detail.identifier;
  const api = app.api;
  app.task(`Sending comment on ${key}…`, async (cx, generation) => {
    await api.comment(key, text);
    if (generation === app.generation) app.open(key, cx);
  }, cx);
}
