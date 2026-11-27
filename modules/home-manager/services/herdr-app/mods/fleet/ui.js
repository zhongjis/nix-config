// Small builders the Agents panel's views share: colors, marks, chips, buttons, the lifecycle strip. They draw
// from a palette (theme()) and hold no state, so main.js and timeline.js stay about what the panel shows.
// Sizes: text is never under 12 px (metadata 12, body 13, names 13 to 15); `muted` is for anything read, `dim` only
// for separators and glyphs; every target is at least 24 px.

import { div, svg, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { theme, settings } from "herdr";
import { agentWord, turnWord } from "./words.js";

export const META = 12, BODY = 13, NAME = 15;
export const ME = "mods/fleet";

// The terminal font, for keys and hashes.
export const mono = () => String(settings()?.font_family ?? "JetBrains Mono");

export const isColor = (c) => typeof c === "string" && c.startsWith("#");

// theme() as the builders take it: its "#rrggbb[aa]" colors.
export function palette() {
  const out = {};
  for (const [k, v] of Object.entries(theme())) if (isColor(v)) out[k] = v;
  return out;
}

// A color with a little alpha, for a ground.
export const tint = (c, alpha = "1f") => `#${c.slice(1, 7)}${alpha}`;

export const agentColor = (t, state) => ({
  working: t.working, running: t.working, blocked: t.blocked, done: t.done, idle: t.idle,
  failed: t.ansi1 ?? t.blocked, ended: t.muted, hibernated: t.muted,
}[state] ?? t.unknown);

const RESULT_COLOR = (t, result) => ({
  succeeded: t.done, failed: t.ansi1 ?? t.blocked, abandoned: t.muted, blocked: t.blocked, uncertain: t.working, closed: t.muted,
}[result] ?? t.done);

// Whose turn it is, as a color: the worker's, the orchestrator's, yours; waiting reads quiet; done by its result.
export const turnColor = (t, task) => ({
  worker: t.working, orch: t.accent, you: t.blocked, waiting: t.muted, slot: t.muted, queued: t.muted,
}[task.turn] ?? RESULT_COLOR(t, task.life?.result));

// A state as a mark that reads without its color.
export function glyph(state, color, size = 12) {
  if (state === "working" || state === "running") return svg("mods/workspace-chrome/spinner.svg").size(size).flex_none().text_color(color).spin(900);
  if (state === "blocked") return svg(`${ME}/alert.svg`).size(size).flex_none().text_color(color);
  if (state === "failed") return svg(`${ME}/failed.svg`).size(size).flex_none().text_color(color);
  if (state === "queued") return svg(`${ME}/queued.svg`).size(size).flex_none().text_color(color);
  if (state === "hibernated") return svg("mods/panda-focus/moon.svg").size(size).flex_none().text_color(color);
  if (state === "done") return div().size(7).mx(2).flex_none().rounded_full().bg(color);
  return div().size(8).mx(2).flex_none().rounded_full().border_1().border_color(color);
}

// The program's icon on a tile; a terminal glyph without one.
export function tile(t, program, size = 24) {
  const ink = program?.color && isColor(program.color) ? program.color : t.foreground;
  const pic = !program?.icon ? svg("mods/workspace-chrome/terminal.svg").size(Math.round(size / 2)).text_color(t.muted)
    : program.tint ? svg(program.icon).size(Math.round(size * 0.58)).text_color(ink) : image(program.icon).w(Math.round(size * 0.58)).h(Math.round(size * 0.58));
  return div().size(size).flex_none().flex().items_center().justify_center().rounded(size > 20 ? 6 : 4)
    .bg(program?.tint && program.tile && isColor(program.tile) ? program.tile : t.raised).child(pic);
}

// An agent's state: a mark and its word; needing you and failing are the only filled ones.
export function badge(t, state, text, extra = "") {
  const c = agentColor(t, state);
  const loud = state === "blocked" || state === "failed";
  return h_flex().h(24).gap(5).flex_none().items_center().text_size(META)
    .when(loud, (el) => el.px(7).rounded(6).bg(tint(c)).font_medium().text_color(c))
    .when(!loud, (el) => el.text_color(t.muted))
    .child(glyph(state, c)).child(text ?? agentWord(state))
    .when(Boolean(extra), (el) => el.child(div().text_color(t.muted).child(extra)));
}

// A ticket key: the task's name in the tree and the detail.
export const keyChip = (t, key) => div().flex_none().h(20).px(6).flex().items_center().rounded(5).bg(t.raised)
  .font_family(mono()).text_size(META).text_color(t.foreground).child(key);

// The turn chip: a border and the turn's color. Yours pulses natively so it reads from across the panel: only a ring
// behind it breathes, the text stays at full opacity (and its contrast).
export function turnChip(t, task, id) {
  const c = turnColor(t, task);
  const you = task.turn === "you";
  return h_flex().id(id).relative().h(22).px(8).gap(5).flex_none().items_center().rounded(11).border_1().border_color(c)
    .text_size(META).font_medium().text_color(you ? c : t.foreground).tooltip(turnWord(task))
    .when(you, (el) => el.bg(tint(c, "1a")).child(div().id(`${id}-ring`).absolute().inset_0().rounded(11).border_2().border_color(c)
      .loop("opacity", { from: 0, to: 0.9, period: 1600 })))
    .child(task.turn === "waiting" ? svg(`${ME}/lock.svg`).size(11).flex_none().text_color(c)
      : task.turn === "you" ? svg(`${ME}/user.svg`).size(11).flex_none().text_color(c)
        : div().size(6).flex_none().rounded_full().bg(c))
    .child(turnWord(task));
}

// CI as a mark that reads without its color (pr-flow's own icons, as the sub-agents popup draws them).
export const CI = (t) => ({
  pass: ["check", t.done, "CI passing"], fail: ["cross", t.blocked, "CI failing"], pending: ["pending", t.working, "CI running"],
});

// The CI mark of a PR the feed has, or null.
export function ciMark(t, pr) {
  const ci = CI(t)[pr?.ci];
  return ci ? svg(`mods/pr-flow/${ci[0]}.svg`).size(12).flex_none().text_color(ci[1]) : null;
}

// A PR as a chip: its number and the CI mark when the PR feed has it.
export function prChip(t, number, pr) {
  const mark = ciMark(t, pr);
  return h_flex().flex_none().gap(4).items_center().text_size(META).text_color(t.muted)
    .child(svg(`${ME}/merge.svg`).size(12).flex_none().text_color(t.muted))
    .child(`PR #${number}`)
    .when(Boolean(mark), (el) => el.child(mark));
}

export function button(t, id, label, { primary = false, enabled = true, h = 28, onClick }) {
  return div().id(id).h(h).px(12).flex().flex_none().items_center().rounded(6).border_1().text_size(META).font_medium()
    .border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
    .text_color(primary ? t.solid_foreground : t.foreground)
    .role("button").accessibility_label(label)
    .when(!enabled, (el) => el.opacity(0.4))
    .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.86)).on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); }))
    .child(label);
}

// A section title with a rule after it.
export const section = (t, title, aside) => h_flex().gap(8).items_center().text_size(META)
  .child(div().font_medium().text_color(t.muted).child(title))
  .when(Boolean(aside), (el) => el.child(div().text_color(t.muted).child(aside ?? "")))
  .child(div().flex_1().h(1).bg(t.border));

// The lifecycle strip: the skill's stops, those passed in a quiet ink, the current one in the turn's color. Each
// cell's width follows its label's length so 12 px labels fit a 368 px panel; `wide` is the detail's.
export const STOPS = ["Dispatched", "Review", "PR", "Ready", "Merged", "Settled"];
export function strip(t, task, width) {
  const now = task.life.stop - 1;
  const c = turnColor(t, task);
  const weights = STOPS.map((s) => s.length + 1.5);
  const room = Math.max(120, width - (STOPS.length - 1) * 3);
  const sum = weights.reduce((a, b) => a + b, 0);
  return h_flex().gap(3).children(STOPS.map((label, i) => v_flex().w(Math.floor(room * weights[i] / sum)).flex_none().gap(4)
    .child(div().h(4).rounded(2).bg(i < now ? tint(t.muted, "99") : i === now ? c : t.input))
    .child(div().text_size(META).truncate().text_color(i === now ? t.foreground : t.muted)
      .when(i === now, (el) => el.font_medium()).child(label))));
}
