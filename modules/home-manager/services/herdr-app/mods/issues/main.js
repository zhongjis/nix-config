// Issue popup; presentation adapted from mrolafsson/herdr-linear (MIT).
import { View } from "gpui-kit";
import { InputState, TextareaState, VirtualListScrollHandle } from "gpui-base";
import { props, closeOverlay, nextCommand } from "herdr";
import { defaults, issueKey, KEY } from "./logic.js";
import { client } from "./transport.js";
import { jira } from "./jira.js";
import { linear } from "./linear.js";
import { screen } from "./screens.js";
import { shown, follow, lookUp } from "./list.js";
import { fields } from "./setup.js";
import { publish, takeOpen, handleOpen } from "./shared.js";

const read = (key, fallback) => JSON.parse(localStorage.getItem(key) ?? "null") ?? fallback;
const message = (error) => String(error?.message ?? error);

export default class Issues extends View {
  init(_props, cx) {
    const saved = read("settings", {});
    this.config = { jira: { ...defaults.jira, ...saved.jira }, linear: { ...defaults.linear, ...saved.linear } };
    this.provider = localStorage.getItem("provider") ?? "jira";
    this.recent = read("recent", {});
    // Each provider's last My issues, shown at once on opening while fresh ones load.
    this.cache = read("cache", {});
    this.jiraItems = this.cache.jira ?? [];
    this.tab = localStorage.getItem("tab") === "recent" ? "recent" : "mine";
    this.page = "list";
    this.issue = this.detail = this.comments = this.menu = this.found = null;
    this.at = 0;
    this.width = 900;
    this.error = this.busy = this.flash = this.listError = "";
    this.loading = this.composing = this.editing = this.advanced = this.closing = false;
    this.generation = this.epoch = 0;
    this.lastOpen = Number(localStorage.getItem("lastOpen") ?? 0);
    this.keys = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.input = InputState.new({ placeholder: "Type to filter, or an issue's key…  ← → to change tabs" });
    this.input.on("change", (_e, cx) => { this.at = 0; lookUp(this, cx); cx.notify(); });
    this.input.on("submit", (_e, cx) => this.enter(cx));
    // The filter keeps the keyboard on the list, so ↑ ↓ reach it after a click.
    this.input.on("blur", (_e, cx) => cx.timer.after(40, () => { if (this.page === "list" && !this.closing) this.input.focus(); }));
    this.draft = TextareaState.new({ rows: 4 });
    this.draft.on("focus", () => { this.editing = true; });
    this.draft.on("blur", () => { this.editing = false; });
    this.fields = fields(this);
    this.linearEnabled = this.config.linear.enabled;
    if (!this.configured().includes(this.provider)) this.provider = this.configured()[0] ?? "jira";
    this.connecting = this.provider;
    this.resetClient();
    this.items = this.cache[this.provider] ?? [];
    this.loaded = Boolean(this.cache[this.provider]);
    publish(this);
    const open = takeOpen(this);
    if (open) handleOpen(this, open, cx);
    else if (this.configured().length) this.load(cx);
    else this.page = "connect";
    this.focus();
    cx.timer.after(300, () => this.focus());
    // `herdr-app do issues.<command>` and key bindings: escape, next, prev, reload.
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "escape") this.escape(cx);
        else if (c === "next" || c === "prev") this.step(cx);
        else if (c === "reload") this.reload(cx);
        cx.notify();
      }
    });
  }
  configured() { return [this.config.jira.url && "jira", this.config.linear.enabled && "linear"].filter(Boolean); }
  resetClient() {
    this.generation++;
    this.epoch++;
    this.loading = false;
    this.api = (this.provider === "jira" ? jira : linear)(this.config[this.provider], client({ ...this.config[this.provider], provider: this.provider }));
  }
  focus() {
    if (this.closing) return;
    if (this.page === "list") this.input.focus();
    else if (this.page === "detail") this.keys.focus();
    else (this.page === "connect" && this.connecting === "linear" ? this.fields.linearToken : this.fields.url).focus();
  }
  go(page, cx) {
    this.page = page;
    this.menu = null;
    cx.timer.after(30, () => this.focus());
    cx.notify();
  }
  say(text, cx, isError = false) {
    this.flash = isError ? "" : text;
    this.error = isError ? text : "";
    cx.notify();
  }
  task(label, work, cx) {
    const generation = this.generation;
    this.busy = label;
    this.error = this.flash = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try { await work(cx, generation); }
      catch (error) { if (generation === this.generation) this.error = message(error); }
      if (generation === this.generation) this.busy = "";
      cx.notify();
    });
  }
  switchProvider(provider, cx, load = true) {
    this.provider = provider;
    localStorage.setItem("provider", provider);
    this.resetClient();
    this.items = this.cache[provider] ?? [];
    this.loaded = Boolean(this.cache[provider]);
    this.issue = this.detail = this.found = null;
    this.at = 0;
    this.listError = this.error = "";
    this.input.set_value("");
    this.go("list", cx);
    publish(this);
    if (load) this.load(cx);
  }
  load(cx) {
    if (this.loading) return;
    const { api, epoch, provider } = this;
    this.loading = true;
    this.listError = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const items = await api.mine();
        if (epoch !== this.epoch) return;
        this.items = items;
        this.loaded = true;
        this.cache[provider] = items;
        localStorage.setItem("cache", JSON.stringify(this.cache));
        if (provider === "jira") this.jiraItems = items;
        publish(this);
      } catch (error) {
        if (epoch === this.epoch) this.listError = message(error);
      }
      if (epoch === this.epoch) this.loading = false;
      cx.notify();
    });
  }
  // Two tabs: either way is the other one.
  step(cx) {
    if (this.page !== "list") return;
    this.tab = this.tab === "mine" ? "recent" : "mine";
    localStorage.setItem("tab", this.tab);
    this.at = 0;
    this.found = null;
    cx.notify();
  }
  enter(cx) {
    const row = this.shown?.[this.at];
    if (row) this.open(row.issue, cx);
    else if (KEY.test(this.input.value().trim())) this.open(this.input.value(), cx);
  }
  open(target, cx) {
    let key = target.identifier;
    if (!key) {
      try { key = issueKey(target); }
      catch (error) { return this.say(error.message, cx, true); }
    }
    this.generation++;
    const api = this.api;
    this.key = key;
    this.issue = target.identifier ? target : null;
    this.detail = this.comments = null;
    this.composing = false;
    this.draft.set_value("");
    this.go("detail", cx);
    this.task(`Loading ${key}…`, async (cx, generation) => {
      const issue = await api.get(key);
      if (generation !== this.generation) return;
      this.issue = this.detail = issue;
      this.recent[this.provider] = [{ ...issue, description: "" }, ...(this.recent[this.provider] ?? []).filter((i) => i.identifier !== issue.identifier)].slice(0, 50);
      localStorage.setItem("recent", JSON.stringify(this.recent));
      cx.notify();
      const comments = await api.comments(key);
      if (generation === this.generation) this.comments = comments;
    }, cx);
  }
  reload(cx) {
    if (this.page === "detail" && this.issue) this.open(this.issue.identifier, cx);
    else if (this.page === "list") this.load(cx);
  }
  back(cx) {
    const id = this.issue?.identifier;
    this.generation++;
    this.busy = this.error = "";
    this.composing = false;
    this.go(this.configured().length ? "list" : "connect", cx);
    const i = (this.shown ?? []).findIndex((r) => r.issue.identifier === id);
    if (i >= 0) this.at = i;
    cx.timer.after(40, () => follow(this));
    if (!this.loaded && this.configured().length) this.load(cx);
  }
  escape(cx) {
    if (this.menu) this.menu = null;
    else if (this.composing) { this.composing = false; this.keys.focus(); }
    else if (this.page === "detail" || (this.page === "settings" && this.configured().length)) this.back(cx);
    else { this.closing = true; closeOverlay(props().overlay); }
    cx.notify();
  }
  copy(text, cx) { cx.write_to_clipboard(text); this.say(`Copied ${text}`, cx); }
  render(cx) {
    // Asked while open: handled after this frame, since render can't notify.
    const open = takeOpen(this);
    if (open) cx.timer.after(1, (cx) => handleOpen(this, open, cx));
    this.shown = shown(this);
    return screen(this, cx);
  }
}
