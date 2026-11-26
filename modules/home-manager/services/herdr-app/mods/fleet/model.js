// The fleet as data: which terminals are roots and children, what each one's status, task and lifecycle
// step are, how urgent each root is, and what the summary strip counts. Pure (no herdr imports), so
// model.check.mjs runs it in node.

/**
 * @typedef {import("herdr").Program} Program
 * @typedef {{ app?: string, msg?: string, state?: string }} Report
 * A core terminal as terminals() / hc ls --json give it: the fields read here.
 * @typedef {{ address: string, name?: string, title?: string, parent?: string, state?: string,
 *   exit_code?: number | null, status?: string | Report | null, report?: Report | null, status_ms?: number | null,
 *   agent?: string, labels?: Record<string, string>, program?: Program | null, where?: string }} Term
 * An agents() entry: the fields read here.
 * @typedef {{ address: string, status: string, space_name?: string, tab_name?: string, title?: string,
 *   pane_name?: string | null, app?: string | null, program?: Program | null }} Agent
 * @typedef {{ text?: string, created_at?: string }} Comment
 * @typedef {{ name: string, fields: Record<string, string>, at: number | null, line: string, body: string }} BeadEvent
 * @typedef {{ id: string, title?: string, status?: string, assignee?: string, metadata?: Record<string, string> }} Bead
 * @typedef {{ bead: Bead, events: BeadEvent[] }} Task
 * @typedef {{ epic: Bead, tasks: Task[] }} Epic
 * @typedef {{ step: number, round: number, pr: string | null, blocked: string | null, result: string | null }} Life
 * @typedef {"agent" | "tool" | "bead" | "ended" | "synthetic"} Kind
 * `status` is the node's own word; `shown` is what its badge says: "supervising" when it rests while
 * something under it works.
 * @typedef {{ id: string, address: string | null, kind: Kind, name: string, app: string | null,
 *   program: Program | null, status: string, shown: string, task: string, report: string, since: number | null,
 *   live: boolean, pane: boolean, tab: string | null, labels: Record<string, string>, worker: boolean,
 *   life: Life | null, bead: Bead | null, events: BeadEvent[], depth: number, children: FleetNode[] }} FleetNode
 * @typedef {{ text: string, needs: number, failed: number, working: number, done: number, tasks: number,
 *   finished: number, unbeaded: number, size: number }} Rollup
 * @typedef {"needs" | "failed" | "working" | "done" | "idle"} Tier
 * @typedef {{ node: FleetNode, space: string, orch: boolean }} Root
 * @typedef {Root & { rollup: Rollup, tier: Tier }} ShownRoot
 * @typedef {{ agents: number, subAgents: number, working: number, needs: number, failed: number, epics: number,
 *   finished: number, tasks: number }} Summary
 * @typedef {{ mode: "fixture", epics: Epic[] } | { mode: "live", byOrch: Map<string, Epic[]> }} Beads
 */

// The worker lifecycle, left to right. A bead's metadata and events pick the step it has reached.
export const STEPS = ["queued", "dispatched", "review", "PR", "merged", "settled"];
// Roots in this order, most urgent first.
export const TIERS = /** @type {const} */ (["needs", "failed", "working", "done", "idle"]);

const ORCH_MARK = /^\[o\]/i;
const WORKER_NAME = /^[wr]-/;

/**
 * An event comment's first line: `event=<name> k=v ...`; anything after it is a free body. Not an event: null.
 * @param {Comment} comment
 * @returns {BeadEvent | null}
 */
export function parseEvent(comment) {
  const [first = "", ...rest] = String(comment?.text ?? "").split("\n");
  const m = /^event=([a-z][a-z0-9-]*)(?: |$)/.exec(first);
  if (!m) return null;
  /** @type {Record<string, string>} */
  const fields = {};
  for (const [, k, v] of first.matchAll(/(?:^| )([a-z][a-z0-9_-]*)=(\S+)/g)) if (k !== "event") fields[k] = v;
  const at = Date.parse(comment?.created_at ?? "");
  return { name: m[1], fields, at: Number.isNaN(at) ? null : at, line: first, body: rest.join("\n").trim() };
}

/**
 * Events of a task, oldest first.
 * @param {Comment[] | null | undefined} comments
 * @returns {BeadEvent[]}
 */
export function eventsOf(comments) {
  /** @type {BeadEvent[]} */
  const out = [];
  for (const c of comments ?? []) { const e = parseEvent(c); if (e) out.push(e); }
  return out.sort((a, b) => (a.at ?? 0) - (b.at ?? 0));
}

/**
 * Where a task bead is: the furthest step its metadata or events prove. blocked_reason (or a blocked bead)
 * holds it at that step.
 * @param {Bead | null} bead
 * @param {BeadEvent[]} events
 * @returns {Life}
 */
export function lifecycle(bead, events) {
  const md = bead?.metadata ?? {};
  /** @param {string} n */
  const has = (n) => events.some((e) => e.name === n);
  const round = Number(md.review_round) || 0;
  let step = 0;
  if (has("dispatched") || has("handed-off") || has("adopted")) step = 1;
  if (round > 0) step = 2;
  if (md.pr_url) step = 3;
  if (md.merged_sha || has("merged")) step = 4;
  if (has("settled")) step = 5;
  const settled = events.filter((e) => e.name === "settled").at(-1);
  const blocked = md.blocked_reason ?? (bead?.status === "blocked" ? "blocked" : null);
  return { step, round, pr: md.pr_url ?? null, blocked, result: settled?.fields.result ?? null };
}

/**
 * A bead with no live terminal: queued until dispatched, then waiting; blocked holds it; merged, settled or
 * closed is done.
 * @param {Bead} bead
 * @param {Life} life
 */
function beadStatus(bead, life) {
  if (life.blocked) return "blocked";
  if (life.step >= 4 || bead.status === "closed") return "done";
  return life.step === 0 ? "queued" : "idle";
}

/**
 * A terminal's word. A listed agent's own; else the core's (a report counts as an agent), error reading as
 * needing the person. A finished terminal failed when it exited nonzero. A live tool with no report is running.
 * @param {Term} k
 * @param {Map<string, Agent>} listed
 * @returns {string}
 */
export function terminalStatus(k, listed) {
  const own = listed.get(k.address)?.status;
  if (own) return own;
  if (k.state && k.state !== "live") return k.exit_code ? "failed" : "idle";
  const s = typeof k.status === "string" ? k.status : k.status?.state ?? k.report?.state;
  if (s === "error") return "blocked";
  return s || "working";
}

/** @param {Term} k @param {Map<string, Agent>} listed */
const isAgent = (k, listed) => listed.has(k.address) || Boolean(k.status ?? k.report) || Boolean(k.program?.agent);
/** Live children, and finished ones that failed: a clean exit is old news. @param {Term} k */
const showable = (k) => (k.state ?? "live") === "live" || Boolean(k.exit_code);

/**
 * @param {Term} k
 * @param {Map<string, Agent>} listed
 * @param {Term[]} all
 * @param {number} depth
 * @returns {FleetNode}
 */
function terminalNode(k, listed, all, depth) {
  const a = listed.get(k.address);
  const name = k.name || a?.pane_name || a?.title || k.title || k.program?.name || k.address;
  const kids = all.filter((c) => c.parent === k.address && showable(c));
  const status = typeof k.status === "object" ? k.status : null;
  // What it last said. Never the terminal's title: that only repeats the name ("π - <msg> - <name>").
  const report = k.report?.msg ?? status?.msg ?? "";
  const word = terminalStatus(k, listed);
  return {
    id: k.address,
    address: k.address,
    kind: isAgent(k, listed) ? "agent" : "tool",
    name,
    app: a?.app ?? k.report?.app ?? status?.app ?? k.agent ?? k.program?.name ?? null,
    program: a?.program ?? k.program ?? null,
    status: word,
    shown: word,
    task: report,
    report,
    since: Number(k.status_ms) || null,
    live: (k.state ?? "live") === "live",
    pane: Boolean(a),
    tab: a?.tab_name ?? null,
    labels: k.labels ?? {},
    worker: WORKER_NAME.test(name) || Boolean(k.labels?.orch),
    life: null,
    bead: null,
    events: [],
    depth,
    children: kids.map((c) => terminalNode(c, listed, all, depth + 1)),
  };
}

/**
 * A task bead with no live terminal, drawn as a worker card under its orchestrator.
 * @param {Task} task
 * @param {number} depth
 * @returns {FleetNode}
 */
function beadNode(task, depth) {
  const life = lifecycle(task.bead, task.events);
  const word = beadStatus(task.bead, life);
  return {
    id: `bead:${task.bead.id}`,
    address: null,
    kind: "bead",
    name: task.bead.assignee || task.bead.metadata?.key || task.bead.id,
    app: task.bead.id,
    program: null,
    status: word,
    shown: word,
    task: task.bead.title ?? "",
    report: "",
    since: task.events.at(-1)?.at ?? null,
    live: false,
    pane: false,
    tab: null,
    labels: {},
    worker: true,
    life,
    bead: task.bead,
    events: task.events,
    depth,
    children: [],
  };
}

/** @param {FleetNode[]} nodes @returns {FleetNode[]} */
const flat = (nodes) => nodes.flatMap((n) => [n, ...flat(n.children)]);

/** @param {FleetNode} node @param {Agent | undefined} agent @param {Term[]} all */
const isOrchestrator = (node, agent, all) =>
  [node.name, agent?.pane_name, agent?.tab_name, agent?.title].some((s) => ORCH_MARK.test(s ?? ""))
  || Boolean(node.labels["orch-context"])
  || all.some((k) => k.labels?.orch === node.address);

/**
 * A task meets its worker: the terminal (or agent name) its latest w-* dispatch names, else the terminal named
 * like the bead's assignee. A matched worker reads as its task (title, id, lifecycle); the rest get bead cards.
 * @param {FleetNode} root
 * @param {Task[]} tasks
 */
export function attachTasks(root, tasks) {
  for (const task of tasks) {
    const sent = task.events.filter((e) => e.name === "dispatched" && (e.fields.agent ?? "").startsWith("w-")).at(-1);
    const who = task.bead.assignee;
    const card = flat(root.children).find((n) => n.kind !== "bead" && !n.bead
      && ((sent && (n.address === sent.fields.terminal || n.name === sent.fields.agent)) || (who && n.name === who)));
    if (card) {
      card.bead = task.bead;
      card.events = task.events;
      card.life = lifecycle(task.bead, task.events);
      card.worker = true;
      card.task = task.bead.title || card.report;
    } else root.children.push(beadNode(task, root.depth + 1));
  }
}

/** @param {Term} k @param {Map<string, string>} spaceNames */
function where(k, spaceNames) {
  const id = k.labels?.["herdr.space"] ?? k.labels?.space ?? "";
  return spaceNames.get(id) ?? (k.labels?.where ?? k.where ?? "").split(" / ")[0] ?? "";
}

/**
 * A node at rest while something under it works is supervising. Set on every node, after beads attach.
 * @param {FleetNode} node
 */
function settleShown(node) {
  for (const c of node.children) settleShown(c);
  const busy = flat(node.children).some((n) => n.live && n.status === "working");
  node.shown = (node.status === "idle" || node.status === "done") && busy && node.kind !== "ended" && node.kind !== "synthetic"
    ? "supervising" : node.status;
}

/**
 * What a root sums up from everything under it: who needs the person, what failed, what works, how far its
 * tasks got (merged, settled or closed counts as done), and how many workers no bead names.
 * @param {FleetNode} root
 * @returns {Rollup}
 */
export function rollup(root) {
  const under = flat(root.children);
  /** @param {string} s */
  const count = (s) => under.filter((n) => n.status === s).length;
  const needs = count("blocked"), failed = count("failed"), done = count("done");
  const working = under.filter((n) => n.live && n.status === "working").length;
  const tasks = under.filter((n) => n.bead);
  const finished = tasks.filter((n) => (n.life?.step ?? 0) >= 4 || n.bead?.status === "closed").length;
  const unbeaded = under.filter((n) => n.worker && !n.bead && n.kind !== "bead").length;
  const parts = [];
  if (needs) parts.push(`${needs} needs you`);
  if (failed) parts.push(`${failed} failed`);
  if (working) parts.push(`${working} working`);
  if (tasks.length) parts.push(`${finished}/${tasks.length} tasks done`);
  else if (done) parts.push(`${done} done`);
  if (!parts.length) parts.push(under.length ? `${under.length} idle` : "No sub-agents");
  return { text: parts.join(" · "), needs, failed, working, done, tasks: tasks.length, finished, unbeaded, size: under.length };
}

/**
 * How urgent a root is, for the order: it, or something under it, needs the person; failed; works (itself or
 * through what it supervises); finished unseen; else idle.
 * @param {FleetNode} node
 * @param {Rollup} r
 * @returns {Tier}
 */
export function tierOf(node, r) {
  if (node.status === "blocked" || r.needs) return "needs";
  if (node.status === "failed" || r.failed) return "failed";
  if (node.shown === "working" || node.shown === "supervising") return "working";
  if (node.shown === "done" || r.done) return "done";
  return "idle";
}

/**
 * A root drawn for something that isn't a listed agent: an ended parent, or the fixture's stand-in orchestrator.
 * @param {string} id
 * @param {Kind} kind
 * @param {string} name
 * @param {string} task
 * @returns {FleetNode}
 */
const standIn = (id, kind, name, task) => ({
  id, address: kind === "ended" ? id : null, kind, name, app: null, program: null, status: "idle", shown: "idle",
  task, report: "", since: null, live: false, pane: false, tab: null, labels: {}, worker: false, life: null,
  bead: null, events: [], depth: 0, children: [],
});

/**
 * The whole view: roots most urgent first, each with its tree, rollup and tier, plus the summary counts.
 * Fixture beads attach to the first orchestrator (or a stand-in one); live beads to each orchestrator they name.
 * @param {{ agents: Agent[], terminals: Term[], spaces?: { id: string, name: string }[], beads?: Beads | null }} input
 */
export function buildFleet({ agents, terminals, spaces = [], beads = null }) {
  const listed = new Map(agents.map((a) => [a.address, a]));
  const byAddress = new Map(terminals.map((k) => [k.address, k]));
  const spaceNames = new Map(spaces.map((s) => [s.id, s.name]));
  // A listed agent under another listed agent reads in its parent's tree, not as a root of its own.
  const nested = new Set(agents.flatMap((a) => flat(terminals.filter((k) => k.parent === a.address)
    .map((k) => terminalNode(k, listed, terminals, 1))).map((n) => n.id)));
  /** @type {Root[]} */
  const roots = agents.filter((a) => !nested.has(a.address)).map((a) => {
    const node = terminalNode(byAddress.get(a.address) ?? { address: a.address, state: "live" }, listed, terminals, 0);
    return { node, space: a.space_name || "", orch: isOrchestrator(node, a, terminals) };
  });
  // Live children whose parent ended: under a stand-in for that parent, so a dead orchestrator's workers still show.
  const placed = new Set([...roots.flatMap((r) => flat([r.node]).map((n) => n.id)), ...nested]);
  const orphans = terminals.filter((k) => k.parent && (k.state ?? "live") === "live" && !placed.has(k.address)
    && !byAddress.has(k.parent) && (isAgent(k, listed) || k.labels?.orch));
  for (const parent of new Set(orphans.map((k) => k.parent ?? ""))) {
    const kids = orphans.filter((k) => k.parent === parent);
    const node = standIn(parent, "ended", `${parent} (ended)`, "Its parent terminal has ended; these kept running.");
    node.children = kids.map((k) => terminalNode(k, listed, terminals, 1));
    roots.push({ node, space: where(kids[0], spaceNames), orch: kids.some((k) => k.labels?.orch === parent) });
  }

  /** @type {Epic[]} */
  let epics = [];
  if (beads?.mode === "fixture" && beads.epics.length) {
    let host = roots.find((r) => r.orch);
    if (!host) {
      host = { node: standIn("fixture-orch", "synthetic", "Fixture orchestrator", "Stand-in orchestrator for the fixture epic."), space: "Fixture", orch: true };
      roots.push(host);
    }
    for (const e of beads.epics) attachTasks(host.node, e.tasks);
    epics = beads.epics;
  } else if (beads?.mode === "live") {
    for (const r of roots.filter((x) => x.orch && x.node.address)) for (const e of beads.byOrch.get(r.node.address ?? "") ?? []) {
      attachTasks(r.node, e.tasks);
      epics.push(e);
    }
  }

  for (const r of roots) settleShown(r.node);
  /** @type {ShownRoot[]} */
  const shown = roots.map((r) => { const ru = rollup(r.node); return { ...r, rollup: ru, tier: tierOf(r.node, ru) }; });
  // Most urgent first; within a tier, the order agents() gives (space, tab, pane).
  const ordered = shown.map((r, i) => ({ r, i }))
    .sort((a, b) => TIERS.indexOf(a.r.tier) - TIERS.indexOf(b.r.tier) || a.i - b.i).map((x) => x.r);
  const everyone = ordered.flatMap((r) => flat([r.node]));
  const terminalsShown = everyone.filter((n) => n.kind === "agent" || n.kind === "tool");
  const allTasks = epics.flatMap((e) => e.tasks);
  /** @type {Summary} */
  const summary = {
    agents: ordered.length,
    subAgents: everyone.filter((n) => n.depth > 0 && n.kind !== "bead").length,
    working: terminalsShown.filter((n) => n.live && n.status === "working").length,
    needs: everyone.filter((n) => n.status === "blocked").length,
    failed: everyone.filter((n) => n.status === "failed").length,
    epics: epics.length,
    finished: allTasks.filter((t) => lifecycle(t.bead, t.events).step >= 4 || t.bead.status === "closed").length,
    tasks: allTasks.length,
  };
  return {
    roots: ordered,
    summary,
    // Agents in the order they're drawn, for agent.next / agent.prev.
    order: everyone.flatMap((n) => (n.kind === "agent" && n.address ? [n.address] : [])),
    // Open first: the most urgent root with something under it, else the first.
    defaultOpen: (ordered.find((r) => r.node.children.length) ?? ordered[0])?.node.id ?? null,
  };
}

/**
 * Depth-first children of a node.
 * @param {FleetNode} node
 */
export const descendants = (node) => flat(node.children);

/**
 * "12m", "3h", "2d": how long a state has held. Null without a start.
 * @param {number | null} ms
 * @param {number} now
 */
export function age(ms, now) {
  if (!ms) return null;
  const m = Math.max(0, Math.floor((now - ms) / 60000));
  if (m < 1) return "now";
  if (m < 60) return `${m}m`;
  if (m < 1440) return `${Math.floor(m / 60)}h`;
  return `${Math.floor(m / 1440)}d`;
}
