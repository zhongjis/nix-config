import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { closeOverlay, focused, hc, layout, nextCommand, props, run, settings, theme } from "herdr";

const find = (node, id) => node?.id === id ? node : (node?.children ?? []).reduce((hit, c) => hit ?? find(c, id), null);

// The right panel stack (herdr-panda): show `child`, or hide the panel when it already shows.
function togglePanel(child) {
  const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
  if (!panel || !body) return;
  if (!panel.hidden && body.active === child) return run("layout.hide", { id: "panel" });
  run("layout.select", { stack: "panel-body", child });
  run("layout.show", { id: "panel" });
}

// Edit these two things to make the example yours. Only repeatable actions
// start a timer: the first key after Ctrl+B can take as long as you like.
// Bindings are shown under their group's heading; one label's keys share a row.
const REPEAT_MS = 500;
const GROUPS = {
  Tabs: [
    ["c", "New tab", "tab.new"],
    ["n", "Next tab", "tab.next"],
    ["N", "Previous tab", "tab.prev"],
    ...Array.from({ length: 10 }, (_, i) => [String(i), `Tab ${i === 0 ? 10 : i}`, "tab.select", { index: i === 0 ? 10 : i }]),
  ],
  Panes: [
    ["%", "Split right", "pane.split", { direction: "right" }],
    ['"', "Split down", "pane.split", { direction: "down" }],
    ["x", "Close pane", "pane.close"],
    ["z", "Zoom pane", "pane.zoom"],
    ["h", "Focus left", "pane.go", { direction: "left" }, true],
    ["j", "Focus down", "pane.go", { direction: "down" }, true],
    ["k", "Focus up", "pane.go", { direction: "up" }, true],
    ["l", "Focus right", "pane.go", { direction: "right" }, true],
    ["left", "Focus left", "pane.go", { direction: "left" }, true],
    ["down", "Focus down", "pane.go", { direction: "down" }, true],
    ["up", "Focus up", "pane.go", { direction: "up" }, true],
    ["right", "Focus right", "pane.go", { direction: "right" }, true],
  ],
  Spaces: [
    ["J", "Next space", "space.next", {}, true],
    ["K", "Previous space", "space.prev", {}, true],
  ],
  Panels: [
    ["p", "Toggle PR panel", () => togglePanel("pr")],
    ["f", "Toggle Files panel", () => togglePanel("files")],
    ["d", "Toggle Changes panel", () => togglePanel("changes")],
    ["a", "Toggle CI panel", () => togglePanel("ci")],
  ],
  Mods: [
    ["i", "Issues", "mod.open", { name: "issues" }],
    ["b", "Browser sessions", "mod.open", { name: "agent-browser" }],
  ],
  Window: [
    ["m", "Minimize window", "window.minimize"],
  ],
};
const BINDINGS = Object.values(GROUPS).flat();
// Arrow keys drawn as arrows on their keycaps (the issues mod's key icons).
const ARROWS = { left: "key-left", right: "key-right", up: "key-up", down: "key-down" };
// The repeat window's bar: drawn full, then emptied a frame or two later.
const BAR_W = 96;
const KICK_MS = 32;

function forwardKey(e, key) {
  if (["enter", "tab", "backspace", "left", "right", "up", "down", "space"].includes(e.key)) return e.key;
  if (key === " ") return "space";
  if (/^[A-Z]$/.test(key)) return `shift+${key.toLowerCase()}`;
  if (key.length === 1 && "abcdefghijklmnopqrstuvwxyz0123456789`\\[],=-.';/".includes(key)) return key === "\\" ? "backslash" : key;
  return null;
}

export default class TmuxPrefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.draining = false;
    this.generation = 0;
    this.all = false;
    // The mod-specific key binding beats the global opener while we're open.
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  send(key, cx) {
    this.generation++;
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // hc starts its subprocess at the call, before closing cancels this view's tasks.
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`tmux-prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  sendPrefix(cx) {
    this.send("ctrl+b", cx);
  }

  key(e, cx) {
    cx.stop_propagation();
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    if (m.control && e.key === "b") return this.sendPrefix(cx);
    const plain = !m.control && !m.alt && !m.platform;
    const key = plain ? (e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key)) : e.key;
    if (plain && key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }
    const binding = plain && BINDINGS.find((b) => b[0] === key);
    if (!binding) {
      const forwarded = this.repeat && plain && forwardKey(e, key);
      if (forwarded) return this.send(forwarded, cx);
      return this.dismiss();
    }
    const [, , command, args = {}, repeatable = false] = binding;
    if (!repeatable) this.dismiss();
    if (typeof command === "function") command();
    else run(command, args);
    if (repeatable) {
      this.repeat = true;
      const generation = ++this.generation;
      this.draining = false;
      cx.timer.after(REPEAT_MS, () => {
        if (this.generation === generation) this.dismiss();
      });
      // The bar is drawn full first, then told to empty: its transition runs natively.
      cx.timer.after(KICK_MS, (cx) => {
        if (this.generation !== generation) return;
        this.draining = true;
        cx.notify();
      });
      cx.notify();
    }
  }

  render() {
    const t = theme();
    const shown = ([key]) => this.all || (!ARROWS[key] && !/^\d$/.test(key));
    const cap = (key) => h_flex().flex_none().min_w(20).h(20).px(5).items_center().justify_center().rounded(5)
      .border_1().border_b_2().border_color(t.border).bg(t.raised).font_family(String(settings().font_family ?? "JetBrains Mono")).text_size(11).text_color(t.foreground)
      .child(ARROWS[key] ? svg(`mods/issues/icons/${ARROWS[key]}.svg`).size(11) : key);
    // One row per label: h and ← are the same "Focus left".
    const rows = (bindings) => bindings.filter(shown).reduce((out, b) => {
      const row = out.find((r) => r[0][1] === b[1]);
      if (row) row.push(b);
      else out.push([b]);
      return out;
    }, []).map((keys) =>
      h_flex().h(22).flex_none().items_center().gap(10).child(h_flex().w(48).flex_none().gap(4).children(keys.map(([key]) => cap(key))))
        .child(div().flex_1().min_w(0).truncate().child(keys[0][1])).child(div().text_size(11).text_color(t.dim).child(keys[0][4] ? "repeat" : "")));
    const group = ([title, bindings]) => v_flex().flex_none().gap(2)
      .child(div().h(18).text_size(11).text_color(t.dim).child(title)).children(rows(bindings));
    // Two columns: tabs and panes, then the rest.
    const column = (groups) => v_flex().flex_1().min_w(0).gap(6).children(groups.filter(([, b]) => b.some(shown)).map(group));
    const groups = Object.entries(GROUPS);
    return v_flex().id("tmux-prefix").track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14).gap(10).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().h(20).flex_none().items_center().justify_between()
        .child(h_flex().gap(10).items_center().child(div().font_semibold().child(this.repeat ? "Repeat" : "Ctrl+B · waiting for a key"))
          .when(this.repeat, (el) => el.child(div().w(BAR_W).h(3).rounded(2).bg(t.border)
            .child(div().id(`repeat-${this.generation}`).h_full().rounded(2).bg(t.accent).w(this.draining ? 0 : BAR_W)
              .transition("width", { duration: REPEAT_MS - KICK_MS, easing: "linear" })))))
        .child(div().text_color(t.muted).child("Esc cancel · ^B send prefix")))
      .child(v_flex().id("tmux-prefix-list").flex_none().max_h(316).overflow_y_scrollbar()
        .child(h_flex().items_start().gap(24).child(column(groups.slice(0, 2))).child(column(groups.slice(2)))))
      .child(div().flex_none().text_color(t.muted).child("0–9 tabs (0 = 10) · arrows focus · ? all bindings"));
  }
}
