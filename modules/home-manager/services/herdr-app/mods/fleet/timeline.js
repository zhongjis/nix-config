// A task's timeline, as the detail draws it (data: model.js timelineOf): a summary bar of who held the task, filters,
// then the events oldest first in rounds. Each event has a time, an actor and its words; a 2 px segment under it in
// the holder's color (dashed while the task waits on you) runs to the next one. timelineView gives its head (summary,
// filters) and its rows apart: main.js puts the rows in the detail's one scroll area and sends it to the end (a
// ScrollHandle) on open, so the newest round is where the eye lands.

import { div, svg, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { took } from "./words.js";
import { FILTER_KEYS, rowPasses } from "./model.js";
import { META, BODY, ME, tint, mono, section } from "./ui.js";

const FILTER_WORDS = { all: "All", decisions: "Decisions", reports: "Reports", instructions: "Instructions" };
const HOLD_WORDS = { worker: "Worker", orch: "Orchestrator", you: "You" };
const CLAMP = 150;

const pad = (n) => String(n).padStart(2, "0");
const clock = (ms) => (ms == null ? "" : `${pad(new Date(ms).getHours())}:${pad(new Date(ms).getMinutes())}`);

// First two lines, cut at CLAMP characters; `more` says the text goes on.
function clamp(text) {
  const lines = text.split("\n").filter((l) => l.trim());
  const head = lines.slice(0, 2).join("\n");
  const more = lines.length > 2 || head.length > CLAMP;
  return { text: more ? `${head.slice(0, CLAMP).trimEnd()}…` : head, more };
}

// Holder colors, by name in the model.
const holderColor = (t, holder) => ({ worker: t.working, orch: t.accent, you: t.blocked, done: t.done }[holder] ?? t.border);

function avatar(t, row, programs) {
  const c = row.kind === "you" ? t.blocked : row.kind === "orch" ? t.accent : t.working;
  const program = row.event.actor === "reviewer" ? programs.reviewer : programs.worker;
  const pic = row.kind === "you" ? svg(`${ME}/user.svg`).size(11).text_color(c)
    : row.kind === "orch" ? svg(`${ME}/orch.svg`).size(11).text_color(c)
      : program?.icon ? (program.tint ? svg(program.icon).size(11).text_color(c) : image(program.icon).w(11).h(11))
        : svg("mods/workspace-chrome/terminal.svg").size(11).text_color(c);
  return div().size(20).mt(1).flex_none().flex().items_center().justify_center().rounded_full().bg(tint(c, "2b")).child(pic);
}

function body(t, row, open, onEvent) {
  const e = row.event, f = e.fields;
  if (e.name === "decided" && (f.q || f.a)) {
    return v_flex().mt(4).px(8).py(6).gap(2).rounded(6).bg(t.raised).text_size(BODY).line_height("18px")
      .when(Boolean(f.q), (el) => el.child(div().text_color(t.muted).child(f.q)))
      .when(Boolean(f.a), (el) => el.child(div().text_color(t.foreground).child(f.a)));
  }
  const full = (e.name === "note" ? (f.detail ?? "") : "") || e.body;
  if (!full) return null;
  // A question to you is shown whole; other bodies fold after two lines.
  const whole = e.name === "blocked" && f.reason === "needs-user";
  const c = whole ? { text: full, more: false } : clamp(full);
  const shown = open ? full : c.text;
  const lead = div().text_size(BODY).line_height("18px").text_color(whole ? t.foreground : t.muted).child(shown);
  if (!c.more) return lead.mt(2);
  return v_flex().id(`ev-${row.key}`).mt(2).min_h(24).cursor_pointer().role("button")
    .accessibility_label(open ? "Show less" : "Show the whole text")
    .on_click((_e, cx) => onEvent(row.key, cx)).child(lead);
}

function eventRow(t, row, last, state, programs, on) {
  const you = row.holder === "you";
  const seg = holderColor(t, row.holder);
  const open = state.ev.has(row.key);
  const text = body(t, row, open, on.event);
  const note = row.note ? `${took(0, row.ms)} ${row.note}` : null;
  return h_flex().items_stretch().gap(8)
    .child(div().w(44).flex_none().flex().justify_end().pt(3).text_size(META).text_color(t.muted).font_family(mono()).child(clock(row.from)))
    .child(div().relative().w(22).flex_none().flex().justify_center()
      .child(avatar(t, row, programs))
      .when(!last, (el) => el.child(you
        ? div().absolute().left(10).top(24).bottom(0).w(2).border_1().border_dashed().border_color(seg)
        : div().absolute().left(10).top(24).bottom(0).w(2).rounded(1).bg(seg))))
    .child(v_flex().flex_1().min_w(0).pt(2).pb(12)
      .child(h_flex().gap(6).items_center().flex_wrap()
        .child(div().text_size(BODY).font_semibold().text_color(row.kind === "you" ? t.blocked : t.foreground).child(row.label))
        .when(Boolean(row.facts), (el) => el.child(div().text_size(META).font_family(mono()).text_color(t.muted).child(row.facts))))
      .when(Boolean(text), (el) => el.child(text))
      .when(Boolean(note), (el) => el.child(div().mt(2).text_size(META).text_color(you ? t.blocked : t.muted).child(note ?? ""))));
}

function roundHeader(t, g, open, on) {
  const total = g.bar.reduce((s, b) => s + b.ms, 0) || 1;
  return h_flex().id(`round-${g.key}`).h(28).px(6).gap(8).items_center().rounded(6).cursor_pointer()
    .role("button").accessibility_label(`Round ${g.n}, ${open ? "open" : "folded"}`)
    .text_size(META).text_color(t.muted).hover((s) => s.bg(t.hover))
    .on_click((_e, cx) => on.round(g.key, !open, cx))
    .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none())
    .child(div().flex_none().font_semibold().text_color(t.foreground).child(`Round ${g.n}`))
    .child(div().flex_none().child(took(0, g.ms)))
    .child(h_flex().flex_1().min_w(40).h(4).rounded(2).overflow_hidden().bg(t.input)
      .children(g.bar.filter((b) => b.ms > 0).map((b) => div().h(4).w(`${(b.ms / total * 100).toFixed(2)}%`).bg(holderColor(t, b.holder)))))
    .child(div().flex_none().truncate().max_w(110).child(g.verdict));
}

// `programs`: { worker, reviewer } program records for the avatars; `on`: { filter, round, event } handlers.
// -> { head, rows }: the title, held-time bar and filter chips; the rounds and events (or a line saying there are none).
// state.last is the index of the last row, for main.js to scroll to.
export function timelineView(t, data, state, programs, on) {
  const totalMs = data.totals.worker + data.totals.orch + data.totals.you || 1;
  const open = (g, i) => state.filter !== "all" || (state.rounds.has(g.key) ? state.rounds.get(g.key)
    : g.n === 0 || i >= data.groups.filter((x) => x.n > 0).length - 2);
  const list = [];
  for (const g of data.groups) {
    const rows = g.rows.filter((r) => rowPasses(r, state.filter));
    if (!rows.length) continue;
    const isOpen = g.n === 0 ? true : open(g, g.n - 1);
    if (g.n > 0) list.push(roundHeader(t, g, isOpen, on));
    if (isOpen) rows.forEach((r, i) => list.push(eventRow(t, r, i === rows.length - 1, state, programs, on)));
  }
  state.last = list.length - 1;
  const head = v_flex().gap(8)
    .child(section(t, "Timeline", `${data.count} events · ${data.roundCount} ${data.roundCount === 1 ? "round" : "rounds"} · ${took(0, data.span)}`))
    .child(v_flex().gap(6)
      .child(h_flex().h(8).rounded(4).overflow_hidden().bg(t.input).accessibility_label(
        ["worker", "orch", "you"].map((k) => `${HOLD_WORDS[k]} ${took(0, data.totals[k]) || "0s"}`).join(", "))
        .children(["worker", "orch", "you"].filter((k) => data.totals[k] > 0)
          .map((k) => div().h(8).w(`${(data.totals[k] / totalMs * 100).toFixed(2)}%`).bg(holderColor(t, k)))))
      .child(h_flex().gap(14).flex_wrap().text_size(META).text_color(t.muted)
        .children(["worker", "orch", "you"].map((k) => h_flex().gap(5).items_center()
          .child(div().size(8).flex_none().rounded_full().bg(holderColor(t, k)))
          .child(HOLD_WORDS[k]).child(div().text_color(t.foreground).font_medium().child(took(0, data.totals[k]) || "0s"))))))
    .child(h_flex().gap(4).flex_wrap().children(FILTER_KEYS.map((k) => div().id(`tf-${k}`).h(24).px(10).flex().items_center().rounded(12)
      .border_1().text_size(META).font_medium().cursor_pointer().role("button")
      .accessibility_label(`Show ${FILTER_WORDS[k].toLowerCase()}`)
      .border_color(state.filter === k ? t.input : t.border).bg(state.filter === k ? t.selected : t.background)
      .text_color(state.filter === k ? t.foreground : t.muted).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => on.filter(k, cx)).child(FILTER_WORDS[k]))));
  const rows = list.length ? list
    : [div().text_size(BODY).text_color(t.muted).child(data.count ? "Nothing matches this filter." : "No events on this bead yet.")];
  return { head, rows };
}
