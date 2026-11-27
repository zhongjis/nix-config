// Tasks of an orchestrator session: beads, their events and the terminals behind them, assembled into rows with a
// lifecycle stop and whose turn it is. Pure: imports events.js only, so node tests load it.
//
// Inputs (plain data, as bd.js loadSession returns it)
//   Bead     { id, title?, status?, assignee?, external_ref?, metadata? }
//   Comment  { text, created_at?, author? }
//   Term     a terminals() entry: { address, name?, state?, status?, ... }
//   Hibernated row   an entry of shared "panda-focus.hibernated": { address?, name, line?, ... }
//
// API
//   sourceLabel(source)          A session source for a header: "ABC-12" from an issue URL, "Linear project", a URL's
//                                host, else the text as given.
//   taskKey(bead)                "ABC-12": the ticket key in external_ref (`.../issue/ABC-12/...` or
//                                `.../browse/ABC-12`, else any `/ABC-12` path segment), else metadata.key
//                                upper-cased, else the bead id.
//   lifecycle(bead, events, reviews)
//                                -> { stop, round, pr, head, ready, merged, settled, result, hold, holdQuestion }
//                                stop: 0 queued, 1 dispatched (dispatched, handed-off or adopted), 2 review
//                                  (metadata review_round > 0 or a review bead), 3 PR (the newest pr= of a report or
//                                  ready event, else metadata pr_url), 4 ready (a ready event newer than the newest
//                                  pushed or pr-opened report), 5 merged (merged_sha or a merged event), 6 settled
//                                  (a settled event no later dispatch or re-instruction superseded, or a closed bead
//                                  without one: result "closed").
//                                round: number; pr, head: string | null; ready, merged, settled: boolean;
//                                result: the settle result (succeeded, failed, ..., closed) | null;
//                                hold: metadata blocked_reason (or "blocked" for a blocked bead) | null;
//                                holdQuestion: what the newest `blocked reason=needs-user` event by the
//                                  orchestrator (an `o-` author) asks (events.js
//                                  questionOf, whole) | null; holdQuestionId: that comment's id | null.
//   buildTasks({ epic, beads, deps, reviews, comments, terms, listed, hibernated, now })
//                                -> task rows, in `beads` order:
//                                { id, key, title, url, status, life, worker, reviewers, waitsOn, blocks, slotWait,
//                                  turn, events, since }
//                                  epic       the epic bead (skipped if it is among `beads`)
//                                  beads      Bead[] the epic's tasks
//                                  deps       { [beadId]: [{ id, type?, status? }] } what each bead depends on; only
//                                             type "blocks" (or none) counts
//                                  reviews    { [taskId]: Bead[] } review beads of a task
//                                  comments   { [beadId]: Comment[] } for tasks and review beads
//                                  terms      terminals()
//                                  listed     Map address -> status of agents() (its word wins over the terminal's)
//                                  hibernated rows of "panda-focus.hibernated"
//                                  now        epoch ms (unused by the assembly; kept for callers' symmetry)
//                                url: http(s) external_ref | null; events: eventsOf(comments), oldest first;
//                                since: time of the newest event | null (when the current turn began);
//                                worker: Worker | null; reviewers: [{ bead, round, open, worker: Worker | null,
//                                  events }] by round: the review bead's `round N` title, else its review_round
//                                  metadata, else its place; an open round's worker may be found by name, a closed
//                                  one's only by the terminal its own events name (the skill reuses r-<stem> names).
//                                Worker = { name, address | null, status, term | null, hibernated | null }
//                                  status: the agents() word, else the terminal's (error -> "blocked"), else
//                                  "hibernated" / "ended" / "failed" (a finished terminal);
//                                waitsOn: [{ id, key, status }] prerequisites ("blocks") not closed;
//                                blocks: [{ id, key }] tasks that wait on this one; slotWait: boolean;
//                                turn: turnOf(task).
//   turnOf(task)                 "done" (settled) | "you" (hold needs-user) | "orch" (any other hold) | "worker"
//                                (worker working) | "orch" (worker blocked at a prompt, or merged) | "waiting"
//                                (waitsOn) | "slot" (slotWait)
//                                | "queued" (not dispatched) | "orch" (newest report newer than the newest
//                                dispatched or re-instructed) | "worker".
//   summary(tasks)               { total, counted, done, failed, ready, merged, inPr, you, waiting, working, text }:
//                                done = settled succeeded (or closed without a settle); failed = settled failed,
//                                blocked or uncertain; abandoned tasks drop out of `counted` (total keeps them);
//                                ready = a PR ready (ready event newer than its pushes) and not merged; merged = tasks
//                                merged, inPr = PR open and not merged, you/waiting/working = tasks whose turn is that.
//                                text, what needs you first, then what moves, then progress: "your turn on ABC-12"
//                                (or "on N tasks"), "N failed", "N working", "N PR ready", "D/T done"; "all done" when
//                                every counted task is done; "" with nothing counted.

import { eventsOf, questionOf } from "./events.js";

const KEYED = /(?:issue|browse)\/([A-Za-z][A-Za-z0-9]*-\d+)(?=[/?#]|$)/;
const ANY_KEY = /\/([A-Za-z][A-Za-z0-9]*-\d+)(?=[/?#]|$)/;

// A session's source as a header says it: the ticket key of an issue URL (ABC-12), "Linear project" for a Linear
// project URL, the host of any other URL, else the text as given (a bead id, a key, "").
export function sourceLabel(source) {
  const s = String(source ?? "").trim();
  if (!/^https?:\/\//.test(s)) return s;
  const m = KEYED.exec(s) ?? ANY_KEY.exec(s);
  if (m) return m[1].toUpperCase();
  if (/linear\.app\/[^/]+\/project\//.test(s)) return "Linear project";
  try {
    return new URL(s).host;
  } catch {
    return s;
  }
}

export function taskKey(bead) {
  const ref = bead?.external_ref ?? "";
  const m = KEYED.exec(ref) ?? ANY_KEY.exec(ref);
  if (m) return m[1].toUpperCase();
  const key = bead?.metadata?.key;
  return key ? String(key).toUpperCase() : (bead?.id ?? "");
}

const lastIndex = (events, test) => {
  for (let i = events.length - 1; i >= 0; i--) if (test(events[i])) return i;
  return -1;
};
const named = (...names) => (e) => names.includes(e.name);
const report = (...kinds) => (e) => e.name === "report" && kinds.includes(e.fields.kind);

export function lifecycle(bead, events, reviews = []) {
  const md = bead?.metadata ?? {};
  const has = (...names) => events.some(named(...names));
  const round = Number(md.review_round) || 0;
  // The newest event naming a PR wins: a replacement PR is reported after the old one was mirrored to pr_url.
  const withPr = lastIndex(events, (e) => (e.name === "report" || e.name === "ready") && Boolean(e.fields.pr));
  const pr = (withPr >= 0 ? events[withPr].fields.pr : null) || md.pr_url;
  const withHead = lastIndex(events, (e) => (e.name === "report" || e.name === "ready") && Boolean(e.fields.head));
  const readyAt = lastIndex(events, named("ready"));
  const ready = readyAt >= 0 && readyAt > lastIndex(events, report("pushed", "pr-opened"));
  const merged = Boolean(md.merged_sha) || has("merged");
  // A settle stands until new work supersedes it (a later dispatch or re-instruction: the task was reopened).
  const settledAt = lastIndex(events, named("settled"));
  const settledEvent = settledAt >= 0 && settledAt > lastIndex(events, named("dispatched", "re-instructed", "handed-off", "adopted"))
    ? events[settledAt] : undefined;
  const settled = Boolean(settledEvent) || bead?.status === "closed";
  let stop = 0;
  if (has("dispatched", "handed-off", "adopted")) stop = 1;
  if (round > 0 || reviews.length > 0) stop = 2;
  if (pr) stop = 3;
  if (ready) stop = 4;
  if (merged) stop = 5;
  if (settled) stop = 6;
  // Only the orchestrator asks the person: a needs-user comment by anyone else is not the question.
  const asked = events[lastIndex(events, (e) => e.name === "blocked" && e.fields.reason === "needs-user" && e.actor === "orch")];
  return {
    stop,
    round,
    pr: pr || null,
    head: withHead >= 0 ? events[withHead].fields.head : null,
    ready,
    merged,
    settled,
    result: settledEvent?.fields.result ?? (settled ? "closed" : null),
    hold: md.blocked_reason || (bead?.status === "blocked" ? "blocked" : null),
    holdQuestion: asked ? questionOf(asked) || null : null,
    holdQuestionId: asked?.id ?? null,
  };
}

const isLive = (t) => (t.state ?? "live") === "live";

// A terminal's word: the agents() one, else the core's (error needs the person); finished: failed or ended.
function termStatus(t, listed) {
  if (!isLive(t)) return t.exit_code ? "failed" : "ended";
  const own = listed?.get?.(t.address);
  if (own) return own === "error" ? "blocked" : own;
  const s = typeof t.status === "string" ? t.status : t.status?.state ?? t.report?.state;
  return s === "error" ? "blocked" : s || "working";
}

// `byName`: a name may find the terminal (a reused reviewer name must not, for a closed round).
function workerOf(name, address, { terms, listed, hibernated }, byName = true) {
  const live = terms.filter(isLive);
  const term = (address && live.find((t) => t.address === address)) || (byName && name && live.find((t) => t.name === name)) || null;
  if (term) return { name: name || term.name, address: term.address, status: termStatus(term, listed), term, hibernated: null };
  const hib = (hibernated ?? []).find((h) => (byName && h.name === name) || (address && h.address === address)) ?? null;
  if (hib) return { name: hib.name, address: hib.address ?? null, status: "hibernated", term: null, hibernated: hib };
  const dead = terms.find((t) => (address && t.address === address) || (byName && name && t.name === name));
  if (dead) return { name: name || dead.name, address: dead.address, status: termStatus(dead, listed), term: dead, hibernated: null };
  return null;
}

const isReview = (b) => /^r-/.test(b.assignee ?? "") || /^review\b/i.test(b.title ?? "");

// A review bead's round: "Review <task> round 2" (the skill's title), else its review_round metadata, else null.
const roundOf = (b) => Number(/\bround (\d+)\b/i.exec(b.title ?? "")?.[1] ?? b.metadata?.review_round) || null;

// Parsed events per comments list, so a render that rebuilds the rows doesn't parse them again.
const parsed = new WeakMap();
const eventsFor = (list) => {
  if (!Array.isArray(list)) return eventsOf(list);
  if (!parsed.has(list)) parsed.set(list, eventsOf(list));
  return parsed.get(list);
};

export function buildTasks({ epic, beads, deps = {}, reviews = {}, comments = {}, terms = [], listed, hibernated = [], now }) {
  const ctx = { terms, listed, hibernated };
  const taskBeads = beads.filter((b) => b.id !== epic?.id);
  const byId = new Map(taskBeads.map((b) => [b.id, b]));
  const keyOf = (id) => (byId.has(id) ? taskKey(byId.get(id)) : id);
  const prereqs = (id) => (deps[id] ?? []).filter((d) => !d.type || d.type === "blocks");
  const tasks = taskBeads.map((bead) => {
    const events = eventsFor(comments[bead.id]);
    const time = (b) => Date.parse(b.created_at ?? "") || 0;
    const revBeads = (reviews[bead.id] ?? []).filter(isReview)
      .map((b, i) => ({ b, round: roundOf(b) ?? i + 1 }))
      .sort((x, y) => x.round - y.round || time(x.b) - time(y.b));
    const life = lifecycle(bead, events, revBeads);
    const dispatch = events[lastIndex(events, (e) => e.name === "dispatched" && /^w-/.test(e.fields.agent ?? ""))];
    const worker = (dispatch && workerOf(dispatch.fields.agent, dispatch.fields.terminal, ctx))
      || (bead.assignee && workerOf(bead.assignee, null, ctx))
      || null;
    const reviewers = revBeads.map(({ b: rb, round }) => {
      const revEvents = eventsFor(comments[rb.id]);
      const sent = revEvents[lastIndex(revEvents, (e) => (e.name === "dispatched" || e.name === "re-instructed") && Boolean(e.fields.terminal))]
        ?? revEvents[lastIndex(revEvents, named("dispatched", "re-instructed"))];
      const open = rb.status !== "closed";
      const worker = workerOf(rb.assignee || sent?.fields.agent, sent?.fields.terminal, ctx, open);
      return { bead: rb, round, open, worker, events: revEvents };
    });
    const waitsOn = prereqs(bead.id)
      .map((d) => ({ id: d.id, key: keyOf(d.id), status: byId.get(d.id)?.status ?? d.status }))
      .filter((d) => d.status !== "closed");
    const lastDispatch = lastIndex(events, named("dispatched", "handed-off", "adopted"));
    const slotWait = lastIndex(events, (e) => e.name === "queued" && e.fields.needs === "slot") > lastDispatch;
    const newest = events.at(-1);
    const task = {
      id: bead.id,
      key: taskKey(bead),
      title: bead.title ?? "",
      url: /^https?:\/\//.test(bead.external_ref ?? "") ? bead.external_ref : null,
      status: bead.status ?? "",
      life,
      worker,
      reviewers,
      waitsOn,
      blocks: [],
      slotWait,
      turn: "queued",
      events,
      since: newest?.at ?? null,
    };
    task.turn = turnOf(task);
    return task;
  });
  const row = new Map(tasks.map((t) => [t.id, t]));
  for (const t of tasks) for (const d of prereqs(t.id)) row.get(d.id)?.blocks.push({ id: t.id, key: t.key });
  return tasks;
}

export function turnOf(task) {
  const { life, worker, events } = task;
  if (life.settled) return "done";
  if (life.hold === "needs-user") return "you";
  if (life.hold) return "orch";
  if (worker?.status === "working") return "worker";
  if (worker?.status === "blocked") return "orch";
  if (life.merged) return "orch";
  if (task.waitsOn.length) return "waiting";
  if (task.slotWait) return "slot";
  if (life.stop === 0) return "queued";
  const reportAt = lastIndex(events, named("report"));
  return reportAt >= 0 && reportAt > lastIndex(events, named("dispatched", "re-instructed")) ? "orch" : "worker";
}

export function summary(tasks) {
  const count = (test) => tasks.filter(test).length;
  const total = tasks.length;
  const settled = (t, ...results) => t.life.settled && results.includes(t.life.result);
  // Abandoned work is no longer part of the session's progress.
  const counted = count((t) => !settled(t, "abandoned"));
  // A merged PR counts once it settles. A closed bead without a settle event counts as done too.
  const done = count((t) => settled(t, "succeeded", "closed"));
  const failed = count((t) => settled(t, "failed", "blocked", "uncertain"));
  const ready = count((t) => t.life.ready && Boolean(t.life.pr) && !t.life.merged && !t.life.settled);
  const merged = count((t) => t.life.merged);
  const inPr = count((t) => t.life.pr && !t.life.merged && !t.life.settled);
  const you = count((t) => t.turn === "you");
  const waiting = count((t) => t.turn === "waiting");
  const working = count((t) => t.turn === "worker");
  const asking = tasks.filter((t) => t.turn === "you");
  const parts = [];
  if (you) parts.push(`your turn on ${you === 1 ? asking[0].key : `${you} tasks`}`);
  if (failed) parts.push(`${failed} failed`);
  if (working) parts.push(`${working} working`);
  if (ready) parts.push(`${ready} PR ready`);
  const text = !counted ? "" : done === counted ? "all done" : [...parts, `${done}/${counted} done`].join(" · ");
  return { total, counted, done, failed, ready, merged, inPr, you, waiting, working, text };
}
