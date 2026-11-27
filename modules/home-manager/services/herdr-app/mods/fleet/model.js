// The Agents panel as data. Pure (imports only the shared pure modules, never "herdr"), so
// tests/fleet-model.mjs runs it in node.
//
// Two kinds of root: an orchestrator draws its session's tasks (shared tasks.js buildTasks, ordered here), any other
// agent draws the terminal tree of what it started, and an agent with nothing under it the solo view.
//
// API
//   buildRoots({ agents, terminals, spaces, nameOf })   roots in agents() order: { node, space, orch, address }
//        node: { id, address, kind: "agent" | "tool" | "ended", name, program, app, status, shown, report, live,
//                pane, tab, labels, children }; status is the node's own word, shown adds what runs under it.
//   descendants(node)                depth-first children
//   isSolo(root, hasEpic)            no children and (not an orchestrator, or no epic)
//   orderTasks(tasks)                dependency order (prerequisites first), settled tasks last
//   sessionView({ session, terms, listed, hibernated, now })
//                                    { epic, mode, source, tasks, summary }: tasks ordered, with the epic's metadata
//   slotsOf(terms, orch)             slots held, as the skill's slot-free.sh counts them: live w-/r- terminals
//                                    labelled orch=<address> whose own status is working
//   prNumber(ref) / prFor(prs, ref)  a PR reference (url, "#12", "12") and its entry in "panda-spaces.prs": a URL
//                                    by that URL, or its repo and number; a bare number only when one repo has it
//   eventLabel(e) / eventShort(e) / eventFacts(e)   words of one bead event
//   newestLine(task, now)            the card's dim line: newest event, its age, what it unblocks
//   timelineOf(events, now)          rounds of rows with holders, spans and totals (see below)
//   rowPasses(row, filter)           the timeline's filters: all, decisions, reports, instructions
//   orchIn(label)                    "orch.in=<ms>:<kind>" -> { at, kind } | null
//   pulsesOf({ task, flip, label, now })   fresh pulses a task's worker moved: [{ key, at, down, tone, kind }]
//   answerState(task, orch)          "answer" | "orch-blocked" | "no-orch" | "worker-prompt" | null
//   answerMessage({ key, id, qid, question, text })   what Send tells the orchestrator: the task, the bead, the
//                                    comment id of the question it answers, the question on one line, the answer
//   reachOf(address, panes, tab)     How a session row reaches a live agent: "peek" (no pane: a hidden worker or
//                                    reviewer), null (its pane is on the current tab), "focus" (a pane elsewhere)

import { kidStatus, treeStatus, isOrchName } from "./tree.js";
import { buildTasks, summary, taskKey } from "./tasks.js";
import { held, rounds } from "./events.js";
import { reportWord, eventWord, ago } from "./words.js";

// ----- terminal tree ---------------------------------------------------------------------------------------------

const isAgent = (k, listed) => listed.has(k.address) || Boolean(k.status ?? k.report) || Boolean(k.program?.agent);
// Live children, and finished ones that failed: a clean exit is old news.
const showable = (k) => (k.state ?? "live") === "live" || Boolean(k.exit_code);

// A root's own word, as the rail reads it (done stays done); a sub-agent's as kidStatus (done is its parent's news).
const rootStatus = (k, listed) => { const s = listed.get(k.address) ?? k.status; return s === "error" ? "blocked" : s; };

function nodeOf(k, ctx, depth) {
  const live = (k.state ?? "live") === "live";
  const agent = isAgent(k, ctx.listed);
  // A live terminal with no word of its own (a tool) is running.
  const own = live ? (depth === 0 ? rootStatus(k, ctx.listed) : kidStatus(k, ctx.listed)) ?? "working" : k.exit_code ? "failed" : "ended";
  const kids = ctx.terminals.filter((c) => c.parent === k.address && showable(c));
  const children = kids.map((c) => nodeOf(c, ctx, depth + 1));
  const under = descendants({ children }).filter((n) => n.live).map((n) => n.status);
  const status = !agent && live && own === "working" ? "running" : own;
  const report = k.report?.msg ?? (typeof k.status === "object" ? k.status?.msg : "") ?? "";
  return {
    id: k.address,
    address: k.address,
    kind: agent ? "agent" : "tool",
    name: ctx.nameOf(k),
    program: k.program ?? null,
    app: k.report?.app ?? k.agent ?? k.program?.name ?? null,
    status,
    shown: agent && live ? treeStatus(own, under) : status,
    report,
    live,
    pane: ctx.listed.has(k.address),
    tab: ctx.tabs?.get(k.address) ?? null,
    labels: k.labels ?? {},
    children,
  };
}

export const descendants = (node) => node.children.flatMap((c) => [c, ...descendants(c)]);

const isOrchestrator = (node, agent, all) =>
  [node.name, agent?.pane_name, agent?.tab_name, agent?.title].some(isOrchName)
  // Workers carry `orch-context` too (their own context script), with an `orch` label naming their parent.
  || (Boolean(node.labels["orch-context"]) && !node.labels.orch)
  || all.some((k) => k.labels?.orch === node.address);

export function buildRoots({ agents, terminals, spaces = [], nameOf }) {
  const listed = new Map(agents.map((a) => [a.address, a.status]));
  const byAgent = new Map(agents.map((a) => [a.address, a]));
  const byAddress = new Map(terminals.map((k) => [k.address, k]));
  const spaceNames = new Map(spaces.map((s) => [s.id, s.name]));
  const tabs = new Map(agents.map((a) => [a.address, a.tab_name]));
  const ctx = { terminals, listed, nameOf, tabs };
  // A listed agent under another listed agent reads in its parent's tree, not as a root of its own.
  const under = (k) => terminals.filter((c) => c.parent === k.address).flatMap((c) => [c, ...under(c)]);
  const nested = new Set(agents.flatMap((a) => under({ address: a.address }).map((k) => k.address)));
  const roots = agents.filter((a) => !nested.has(a.address)).map((a) => {
    const node = nodeOf(byAddress.get(a.address) ?? { address: a.address, state: "live", status: a.status }, ctx, 0);
    return { node, address: a.address, space: a.space_name || spaceNames.get(a.space) || "", orch: isOrchestrator(node, byAgent.get(a.address), terminals) };
  });
  // Live children whose parent ended (gone, or still listed as finished): under a stand-in for that parent, so a dead
  // orchestrator's workers still show.
  const placed = new Set([...roots.flatMap((r) => [r.node, ...descendants(r.node)].map((n) => n.address)), ...nested]);
  const orphans = terminals.filter((k) => k.parent && (k.state ?? "live") === "live" && !placed.has(k.address)
    && !placed.has(k.parent) && (byAddress.get(k.parent)?.state ?? "gone") !== "live" && (isAgent(k, listed) || k.labels?.orch));
  for (const parent of new Set(orphans.map((k) => k.parent))) {
    const kids = orphans.filter((k) => k.parent === parent);
    const node = {
      id: parent, address: parent, kind: "ended", name: `${parent} (ended)`, program: null, app: null, status: "ended",
      shown: "ended", report: "Its parent terminal has ended; these kept running.", live: false, pane: false, tab: null,
      labels: {}, children: kids.map((k) => nodeOf(k, ctx, 1)),
    };
    const first = kids[0];
    roots.push({ node, address: parent, space: spaceNames.get(first?.labels?.["herdr.space"] ?? first?.labels?.space) ?? "",
      orch: kids.some((k) => k.labels?.orch === parent) });
  }
  return roots;
}

export const isSolo = (root, hasEpic) => root.node.children.length === 0 && (!root.orch || !hasEpic);

// ----- tasks -----------------------------------------------------------------------------------------------------

// Prerequisites first (a task that blocks another comes before it), ties in bd's order; settled tasks go last,
// in the same order among themselves.
export function orderTasks(tasks) {
  const ids = new Set(tasks.map((t) => t.id));
  const indegree = new Map(tasks.map((t) => [t.id, 0]));
  for (const t of tasks) for (const b of t.blocks) if (ids.has(b.id)) indegree.set(b.id, indegree.get(b.id) + 1);
  const out = [];
  const left = [...tasks];
  while (left.length) {
    const i = left.findIndex((t) => indegree.get(t.id) === 0);
    const [t] = left.splice(i < 0 ? 0 : i, 1);
    out.push(t);
    for (const b of t.blocks) if (indegree.has(b.id)) indegree.set(b.id, indegree.get(b.id) - 1);
  }
  const done = (t) => t.turn === "done";
  return [...out.filter((t) => !done(t)), ...out.filter(done)];
}

// The ticket the session works from: its epic's external_ref key, else a source in its metadata.
function sourceOf(epic) {
  const md = epic?.metadata ?? {};
  const key = taskKey(epic);
  if (key && key !== epic?.id) return key;
  return md.source || md.ticket || md.source_ticket || null;
}

export function sessionView({ session, terms, listed, hibernated, now }) {
  const rows = buildTasks({ ...session, terms, listed, hibernated, now });
  const tasks = orderTasks(rows);
  return { epic: session.epic, mode: session.mode ?? null, source: sourceOf(session.epic), tasks, summary: summary(tasks) };
}

// Slots held against --max, counted as the skill's slot-free.sh does: this orchestrator's live w-/r- terminals
// (labelled orch=<address>) whose own status is working.
export function slotsOf(terms, orch) {
  const own = (k) => (typeof k.status === "string" ? k.status : k.status?.state);
  return terms.filter((k) => (k.state ?? "live") === "live" && k.labels?.orch === orch && /^[wr]-/.test(k.name ?? "")
    && own(k) === "working").length;
}

// ----- PRs -------------------------------------------------------------------------------------------------------

export const prNumber = (ref) => /(?:\/pull\/|#|^)(\d+)\/?$/.exec(String(ref ?? "").trim())?.[1] ?? null;

// The entry of shared "panda-spaces.prs" ({ [repo]: [{ number, url, ci, ... }] }) a task's PR reference names:
// by url, else by number when only one repo has it. Returns { ...pr, repo } | null.
// A PR URL's repo with its forge, as "host/owner/name" (lower case), or null. The same owner/name on another host
// is another repo.
const repoOf = (url) => /^https?:\/\/([^/]+\/[^/]+\/[^/]+)\/pull\/\d+/.exec(String(url ?? ""))?.[1]?.toLowerCase() ?? null;
// A "panda-spaces.prs" key with its forge: "host/owner/name" as given, "owner/name" on github.com.
const feedRepo = (key) => { const k = String(key ?? "").toLowerCase(); return k.split("/").length === 3 ? k : `github.com/${k}`; };

export function prFor(prs, ref) {
  const all = Object.entries(prs ?? {}).flatMap(([repo, list]) => (list ?? []).map((p) => ({ ...p, repo })));
  const url = String(ref ?? "").trim().replace(/\/+$/, "");
  const n = prNumber(ref);
  if (url.includes("/")) {
    const byUrl = all.find((p) => String(p.url ?? "").replace(/\/+$/, "") === url);
    if (byUrl) return byUrl;
    // The same repo and number (the feed's URL may differ in form); never another repo's PR with that number.
    const repo = repoOf(url);
    return (repo && n && all.find((p) => String(p.number) === n && (p.url ? repoOf(p.url) === repo : feedRepo(p.repo) === repo))) || null;
  }
  const same = n ? all.filter((p) => String(p.number) === n) : [];
  return same.length === 1 ? same[0] : null;
}

// ----- events ----------------------------------------------------------------------------------------------------

export function eventLabel(e) {
  if (e.name === "report") return `Reported · ${reportWord(e.fields.kind)}`;
  if (e.name === "decided") return e.fields.by === "user" ? "You decided" : "Orchestrator decided";
  if (e.name === "blocked") return e.fields.reason === "needs-user" ? "Asked you" : "Blocked";
  return eventWord(e.name);
}

// The words alone, for the card's dim line.
export const eventShort = (e) => (e.name === "report" ? reportWord(e.fields.kind) : eventLabel(e));

export function eventFacts(e) {
  const f = e.fields, pr = prNumber(f.pr);
  return [e.name === "dispatched" && f.kind ? f.kind : null, f.terminal ?? null,
    e.name === "dispatched" && f.result && f.result !== "working" ? f.result : null, f.head ? f.head.slice(0, 7) : null,
    pr ? `#${pr}` : null].filter(Boolean).join(" · ");
}

const unblocks = (task) => (task.blocks.length && !task.life.merged ? `Merging it readies ${task.blocks.map((b) => b.key).join(", ")}` : "");

export function newestLine(task, now) {
  const e = task.events.at(-1);
  const parts = [];
  if (e) {
    const facts = e.name === "report" || e.name === "ready" ? eventFacts(e) : "";
    parts.push([eventShort(e), facts].filter(Boolean).join(" "));
    if (e.at) parts.push(ago(e.at, now));
  } else parts.push("No events yet");
  const next = unblocks(task);
  if (next) parts.push(next);
  return parts.join(" · ");
}

// ----- timeline --------------------------------------------------------------------------------------------------

export const LONG_HOLD = 30 * 60000;

// Who an event's avatar shows: you (your decision, or the question that waits on you), the orchestrator, or a worker.
function avatarOf(e) {
  if (e.name === "decided" && e.fields.by === "user") return "you";
  if (e.name === "blocked" && e.fields.reason === "needs-user") return "you";
  return e.actor === "orch" ? "orch" : e.actor === "reviewer" ? "reviewer" : "worker";
}

const HOLD_NOTE = { you: "waiting on you", worker: "worker at work", orch: "with the orchestrator" };

// Rows (one per event, in time order) with who held the task after it and for how long; grouped in rounds with their
// own held-time bar; totals for the summary bar. A row's key is its time and index, so a poll never moves what's open.
export function timelineOf(events, now) {
  const { spans, totals } = held(events, now);
  const rows = new Map();
  spans.forEach((s, i) => {
    const e = s.event;
    rows.set(e, {
      key: `${e.at ?? 0}:${i}`, i, event: e, holder: s.holder, from: s.from, to: s.to, ms: s.ms,
      kind: avatarOf(e), label: eventLabel(e), facts: eventFacts(e),
      note: s.ms > LONG_HOLD && HOLD_NOTE[s.holder] ? HOLD_NOTE[s.holder] : null,
    });
  });
  const groups = rounds(events).map((r) => {
    const list = r.events.map((e) => rows.get(e));
    const from = list[0]?.from ?? null, to = list.at(-1)?.to ?? null;
    const lastReport = [...list].reverse().find((x) => x.event.name === "report");
    return {
      n: r.n, key: `r${r.n}:${r.at ?? 0}`, rows: list, ms: from != null && to != null ? Math.max(0, to - from) : 0,
      bar: list.map((x) => ({ holder: x.holder, ms: x.ms })),
      verdict: lastReport ? reportWord(lastReport.event.fields.kind) : "in progress",
    };
  });
  const first = events[0]?.at ?? null;
  return { groups, totals, span: first != null ? Math.max(0, now - first) : 0, count: events.length, roundCount: groups.filter((g) => g.n > 0).length };
}

const FILTERS = {
  all: () => true,
  decisions: (e) => e.name === "decided" || e.name === "blocked",
  reports: (e) => e.name === "report",
  instructions: (e) => e.name === "dispatched" || e.name === "re-instructed",
};
export const FILTER_KEYS = ["all", "decisions", "reports", "instructions"];
export const rowPasses = (row, filter) => (FILTERS[filter] ?? FILTERS.all)(row.event);

// ----- pulses ----------------------------------------------------------------------------------------------------

export const PULSE_WINDOW = 5000;

export function orchIn(label) {
  const m = /^(\d{10,})(?::(.+))?$/.exec(String(label ?? "").trim());
  return m ? { at: Number(m[1]), kind: m[2] ?? "" } : null;
}

// What a task's worker did in the last PULSE_WINDOW: a status flip seen live (Clock.flip) and a fresh `orch.in`
// label. down: the orchestrator sent; up: the worker answered. tone: the color's name in the theme.
export function pulsesOf({ task, flip, label, now }) {
  const out = [];
  const addr = task.worker?.address;
  if (!addr || task.turn === "done") return out;
  if (flip && now - flip.at < PULSE_WINDOW) {
    if (flip.to === "working") out.push({ key: `flip:${addr}:${flip.at}`, at: flip.at, down: true, tone: "accent", kind: "" });
    else if (flip.from === "working" && (flip.to === "idle" || flip.to === "done")) out.push({ key: `flip:${addr}:${flip.at}`, at: flip.at, down: false, tone: "done", kind: "" });
    else if (flip.to === "blocked") out.push({ key: `flip:${addr}:${flip.at}`, at: flip.at, down: false, tone: "blocked", kind: "" });
  }
  const sent = orchIn(label);
  if (sent && now - sent.at < PULSE_WINDOW && sent.at <= now + 1000) out.push({ key: `in:${addr}:${sent.at}`, at: sent.at, down: true, tone: "accent", kind: sent.kind });
  return out;
}

// ----- answers ---------------------------------------------------------------------------------------------------

// Where a task's question goes: on your turn, to the orchestrator (not when it is blocked itself, or gone); a worker
// stuck at its own prompt is the orchestrator's to answer.
export function answerState(task, orch) {
  if (task.turn === "you") {
    if (!orch || !orch.live) return "no-orch";
    return orch.status === "blocked" ? "orch-blocked" : "answer";
  }
  if (task.turn === "orch" && task.worker?.status === "blocked") return "worker-prompt";
  return null;
}

const oneLine = (s) => String(s ?? "").replace(/\s+/g, " ").trim();

export const answerMessage = ({ key, id, qid, question, text }) =>
  `Answer from the herdr-app panel for ${key} (bead ${id}, question ${qid}). Question: ${oneLine(question)}. Answer: ${oneLine(text)}`;

// ----- session rows ----------------------------------------------------------------------------------------------

export function reachOf(address, panes, tab) {
  const pane = (panes ?? []).find((p) => p.terminal === address);
  if (!pane) return "peek";
  return pane.tab === tab ? null : "focus";
}
