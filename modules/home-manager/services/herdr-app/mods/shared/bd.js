// Beads for the agent surfaces, read-only except closeEpic. The app's own environment can hold a stale BEADS_DIR,
// so bd runs with the login shell's (beadsDir()). The only shared module that talks to herdr (exec, hc).
//
// An orchestrator's session is its newest open epic (by created_at, then id): the rail, the panel, next-needs and
// fleet.open all read that one. Older open epics show only on the beads board.
//
// API (all async; bd failures reject with BeadsError, exec's own errors pass through)
//   BeadsError                       Error subclass; message is bd's first non-warning stderr line.
//   beadsDir()                       The login shell's BEADS_DIR ("" when it sets none), asked once.
//   bdJson(dir, args)                `bd <args> --json` as a list (an object becomes [object], null []). `dir` "" runs
//                                    bd with the app's env.
//   bdConfig(dir, key)               `bd config get <key>`'s value, "" when unset.
//   statusMs(address)                `hc get <address> --json`'s status_ms (number | null): the fetch for Clock.
//   newestEpic(epics)                The session epic of a list of open epics: newest created_at, then highest id.
//   loadEpic(epic, dir)              -> Session: one epic, read in full.
//   loadSession(orch, dir)           -> { session: Session | null, extra }: orchestrator terminal `orch`'s newest open
//                                    epic in full; extra: how many older open epics it has.
//   loadSummaries(orchs, dir)        -> Map<orch, { session, extra }> for every asked orch (session null without an
//                                    open epic): the same read as loadSession, so the rail and the panel agree. One
//                                    epic list for all of them; an orch whose read failed is left out of the Map.
//   loadAllSessions(dir)             -> [{ epic, orch, counts }]: every open epic; orch: its metadata
//                                    `session` (terminal address) | null; counts: { total, <status>: n } of its children.
//   epicState(dir, id)               -> { epic: Bead, children: Bead[] } read now (the beads view's Close check).
//   liveHold(dir, id)                -> { hold, question }: bead `id` read now: hold its metadata blocked_reason
//                                    | null; question the newest `blocked reason=needs-user` event by an `o-` author
//                                    { id, text } | null.
//   closeEpic(dir, id)               `bd close <id>`; for the beads view's confirmed click only.
//
//   Bead     { id, title, status, assignee, external_ref, labels, metadata, created_at, updated_at }
//   Comment  { id, text, created_at, author }
//   Session  { epic: Bead, mode: { flags, max, at } | null, beads: Bead[], deps, reviews, comments }
//     mode:     the epic's newest `event=mode` (flags: string | null, max: number | null, at: ms | null)
//     beads:    the epic's tasks; deps: { [id]: [{ id, type, status }] }; reviews: { [taskId]: Bead[] } review beads
//               (children of tasks with metadata review_round > 0); comments: { [beadId]: Comment[] } of the epic,
//               the tasks and the review beads.
//   Feed a Session to tasks.js buildTasks({ ...session, terms, listed, hibernated, now }).
//
// Cost of one session read: `bd list` of the epic's children, one `bd list` per task under review, and one batched
// `bd show --include-comments` of the epic, its tasks and their review beads (dependencies and comments together).

import { exec, hc } from "herdr";
import { eventsOf, questionOf } from "./events.js";

export class BeadsError extends Error {}

const OPEN = "open,in_progress,blocked,deferred";
const obj = (x) => (x && typeof x === "object" ? Object.fromEntries(Object.entries(x)) : {});
const str = (x) => (typeof x === "string" ? x : undefined);

// bd's metadata: an object, or the same as a JSON string. Values read as text.
function metadata(x) {
  let md = x;
  if (typeof x === "string") {
    try { md = JSON.parse(x); } catch (e) { if (e instanceof SyntaxError) md = {}; else throw e; }
  }
  return Object.fromEntries(Object.entries(obj(md)).map(([k, v]) => [k, String(v)]));
}

const toBead = (x) => {
  const o = obj(x);
  return {
    id: str(o.id) ?? "",
    title: str(o.title),
    status: str(o.status),
    assignee: str(o.assignee),
    external_ref: str(o.external_ref),
    labels: Array.isArray(o.labels) ? o.labels.map(String) : [],
    metadata: metadata(o.metadata),
    created_at: str(o.created_at),
    updated_at: str(o.updated_at),
  };
};
const toComment = (x) => { const o = obj(x); return { id: str(o.id), text: str(o.text), created_at: str(o.created_at), author: str(o.author) }; };

// `bd show --json` entries give { id, status, dependency_type }; `bd list --json` entries { depends_on_id, type }.
const toDeps = (list) => (Array.isArray(list) ? list : []).map((d) => {
  const o = obj(d);
  return { id: str(o.depends_on_id) ?? str(o.id) ?? "", type: str(o.dependency_type) ?? str(o.type) ?? "blocks", status: str(o.status) };
});

export async function beadsDir() {
  const r = await exec("zsh", ["-lc", 'printf %s "$BEADS_DIR"'], { timeout: 10000 });
  return r.code === 0 ? r.stdout.trim() : "";
}

const run = (dir, argv) => (dir
  ? exec("/usr/bin/env", [`BEADS_DIR=${dir}`, "bd", ...argv], { timeout: 15000 })
  : exec("bd", argv, { timeout: 15000 }));

const fail = (r) => {
  const why = r.stderr.split("\n").map((l) => l.trim()).find((l) => l && !/^(warning:|Fix:|Or:|Hint:)/.test(l));
  return new BeadsError(why ?? `bd exited ${r.code}`);
};

export async function bdJson(dir, args) {
  const r = await run(dir, [...args, "--json"]);
  if (r.code !== 0) throw fail(r);
  const out = JSON.parse(r.stdout.trim() || "[]");
  if (out == null) return [];
  return Array.isArray(out) ? out : [out];
}

export async function statusMs(address) {
  const r = await hc(["get", address, "--json"]);
  if (r.code !== 0) return null;
  const ms = Number(JSON.parse(r.stdout || "{}")?.status_ms);
  return Number.isFinite(ms) && ms > 0 ? ms : null;
}

export async function bdConfig(dir, key) {
  const [o] = await bdJson(dir, ["config", "get", key]);
  return str(obj(o).value) ?? "";
}

export async function closeEpic(dir, id) {
  const r = await run(dir, ["close", id, "--reason", "Closed from the herdr-app beads view"]);
  if (r.code !== 0) throw fail(r);
}

const children = async (dir, id) => (await bdJson(dir, ["list", "--parent", id, "--all", "--limit", "0"])).map(toBead);
const openEpics = async (dir, filter = []) => (await bdJson(dir, ["list", "--type", "epic", ...filter, "--status", OPEN, "--limit", "0"])).map(toBead);
const isReview = (b) => /^r-/.test(b.assignee ?? "") || /^review\b/i.test(b.title ?? "");

function modeOf(epicComments) {
  const e = eventsOf(epicComments).filter((x) => x.name === "mode").at(-1);
  if (!e) return null;
  const max = Number(e.fields.max);
  return { flags: e.fields.flags ?? null, max: e.fields.max !== undefined && Number.isFinite(max) ? max : null, at: e.at };
}

export function newestEpic(epics) {
  const t = (e) => { const ms = Date.parse(e.created_at ?? ""); return Number.isNaN(ms) ? 0 : ms; };
  return [...epics].sort((a, b) => t(b) - t(a) || (a.id < b.id ? 1 : a.id > b.id ? -1 : 0))[0] ?? null;
}

export async function loadEpic(epic, dir) {
  const beads = await children(dir, epic.id);
  const reviews = {};
  await Promise.all(beads.filter((b) => Number(b.metadata.review_round) > 0).map(async (b) => {
    reviews[b.id] = (await children(dir, b.id)).filter(isReview);
  }));
  const deps = {};
  const byId = {};
  // One `bd show` for the epic, every task and review bead: prerequisites with their status, and the comments.
  const ids = [epic.id, ...beads.map((b) => b.id), ...Object.values(reviews).flat().map((b) => b.id)];
  for (const s of await bdJson(dir, ["show", ...ids, "--include-comments", "--brief-deps"])) {
    const o = obj(s), id = str(o.id) ?? "";
    deps[id] = toDeps(o.dependencies).filter((d) => d.type === "blocks");
    byId[id] = (Array.isArray(o.comments) ? o.comments : []).map(toComment);
  }
  return { epic, mode: modeOf(byId[epic.id] ?? []), beads, deps, reviews, comments: byId };
}

export async function loadSession(orch, dir) {
  const epics = await openEpics(dir, ["--metadata-field", `session=${orch}`]);
  const epic = newestEpic(epics);
  return { session: epic ? await loadEpic(epic, dir) : null, extra: Math.max(0, epics.length - 1) };
}

export async function loadSummaries(orchs, dir) {
  const out = new Map();
  const epics = await openEpics(dir);
  await Promise.all([...orchs].map(async (orch) => {
    const mine = epics.filter((e) => e.metadata.session === orch);
    const epic = newestEpic(mine);
    try {
      out.set(orch, { session: epic ? await loadEpic(epic, dir) : null, extra: Math.max(0, mine.length - 1) });
    } catch (e) {
      if (!(e instanceof BeadsError) && !(e instanceof SyntaxError)) throw e;
    }
  }));
  return out;
}

export async function loadAllSessions(dir) {
  const epics = await openEpics(dir);
  return Promise.all(epics.map(async (epic) => {
    const counts = { total: 0 };
    for (const b of await children(dir, epic.id)) {
      counts.total++;
      const s = b.status ?? "open";
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return { epic, orch: epic.metadata.session ?? null, counts };
  }));
}

export async function epicState(dir, id) {
  const [epic] = (await bdJson(dir, ["show", id])).map(toBead);
  return { epic: epic ?? null, children: await children(dir, id) };
}

export async function liveHold(dir, id) {
  const [o] = await bdJson(dir, ["show", id, "--include-comments"]);
  const bead = toBead(o);
  const comments = (Array.isArray(obj(o).comments) ? obj(o).comments : []).map(toComment);
  const asked = eventsOf(comments).filter((e) => e.name === "blocked" && e.fields.reason === "needs-user" && e.actor === "orch").at(-1);
  return { hold: bead.metadata.blocked_reason || null, question: asked ? { id: asked.id, text: questionOf(asked) } : null };
}
