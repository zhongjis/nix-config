// Pure helpers of the beads view: the blocks graph in columns, its connectors, session rows, a ticket's reference,
// the keyboard's meaning. Imports nothing, so node tests load it (tests/beads-view.mjs).
//
// API
//   remoteRef(ref)               external_ref -> { provider: "linear" | "jira" | null, key, base, url } | null.
//                                key: "ABC-12" | null; base: the Jira site (everything before `/browse/`) | null.
//   sourceOf(epic)               The short name of where an epic came from: a ticket key, "Linear project", a host,
//                                else "ad hoc". Reads metadata `source` (planning refs), then external_ref.
//   isStale(item, liveOrchs)     { epic, orch, counts } of loadAllSessions: a session epic (metadata `session`) with
//                                no child left open (none at all counts) and the orchestrator's terminal gone
//                                (liveOrchs: a Set of live terminal addresses) -> "ended without --off".
//   isNewestOpen(item, items)    Whether `item` is its orchestrator's newest open epic (created_at): the only one the
//                                Agents panel shows.
//   segments(counts)             counts { total, closed, in_progress, blocked, ... } -> one kind per child, in order:
//                                "closed", "active", "blocked", "open".
//   levels(tasks)                task rows (tasks.js) -> { cols: id[][], col: Map<id, index>, edges: [{ from, to }] }.
//                                A task's column is its longest chain of `blocks` prerequisites inside the epic;
//                                a column is ordered by where its prerequisites sit.
//   place(tasks, sizes)          levels + pixel boxes: { nodes: Map<id, {x,y,w,h,col,row}>, width, height, cols, edges }.
//                                sizes { card, gap, pad, head, heightOf(task), rowGap }.
//   elbow(a, b, r)               The pieces of a 1 px connector from point a {x, y} to b, turning in the gap before b:
//                                [{ x, y, w, h, corner?, r? }]; corner "tr" | "br" | "bl" | "tl" is the rounded one, radius r.
//   sessionsOf(task, ctx)        Every w- and r- terminal that touched a task (dispatch events, review beads), newest
//                                last: [{ name, role, round, address, state, term, program, resume }]. One row per
//                                worker name (its newest address), one per reviewer and review round.
//                                ctx { terms, listed, hibernated }. state: working | blocked | idle | done | hibernated |
//                                ended | failed | gone.
//   driftOf(events)              The newest `event=note detail=remote body changed...` -> { at, text } | null.
//   pickDefault(tasks)           The task the inspector opens on: yours first, then a worker's, then the rest.
//   graphStep(graph, id, dir)    The task id next to `id` for "up" | "down" | "left" | "right", or `id`.
//   parseKey(e)                  { key, modifiers } -> "up" | "down" | "left" | "right" | "enter" | "tab" | "shift-tab" |
//                                "escape" | null (anything with ctrl, alt or the platform key is not ours).
//   shortPath(path, home)        `path` with the home folder as "~".

const KEY = "[A-Za-z][A-Za-z0-9]*-\\d+";
const URL_PARTS = /^(https?:\/\/[^/\s?#]+)(\/[^?#\s]*)?/;

export function remoteRef(ref) {
  const m = URL_PARTS.exec(String(ref ?? "").trim());
  if (!m) return null;
  const [, origin, path = ""] = m;
  const host = origin.replace(/^https?:\/\//, "").toLowerCase();
  if (host === "linear.app" || host.endsWith(".linear.app")) {
    const key = new RegExp(`/issue/(${KEY})(?=[/?#]|$)`).exec(path)?.[1];
    return { provider: "linear", key: key ? key.toUpperCase() : null, base: null, url: m[0] };
  }
  const browse = new RegExp(`^(.*)/browse/(${KEY})(?=[/?#]|$)`).exec(path);
  if (browse) return { provider: "jira", key: browse[2].toUpperCase(), base: origin + browse[1], url: m[0] };
  return { provider: null, key: new RegExp(`/(${KEY})(?=[/?#]|$)`).exec(path)?.[1]?.toUpperCase() ?? null, base: null, url: m[0] };
}

export function sourceOf(epic) {
  const refs = [...String(epic?.metadata?.source ?? "").split(/\s+/), epic?.external_ref ?? ""].filter(Boolean);
  const ref = refs[0];
  if (!ref) return "ad hoc";
  const r = remoteRef(ref);
  if (!r) return ref;
  if (r.key) return r.key;
  const host = URL_PARTS.exec(ref)?.[1].replace(/^https?:\/\//, "") ?? ref;
  if (r.provider === "linear") return /\/project\//.test(ref) ? "Linear project" : "Linear";
  return host;
}

export function isStale(item, liveOrchs) {
  const c = item?.counts ?? {};
  if (!item?.epic?.metadata?.session) return false;
  return (c.total ?? 0) === (c.closed ?? 0) && !(item.orch && liveOrchs.has(item.orch));
}

// The Agents panel shows an orchestrator's newest open epic (newest created_at, the id breaks a tie) only.
export function isNewestOpen(item, items) {
  if (!item?.orch) return false;
  const t = (i) => { const ms = Date.parse(i.epic.created_at ?? ""); return Number.isNaN(ms) ? 0 : ms; };
  const newer = (a, b) => t(a) - t(b) || (a.epic.id > b.epic.id ? 1 : -1);
  const best = items.filter((i) => i.orch === item.orch).reduce((a, b) => (newer(b, a) > 0 ? b : a), item);
  return best.epic.id === item.epic.id;
}

export function segments(counts) {
  const c = counts ?? {};
  const total = c.total ?? 0;
  const closed = c.closed ?? 0, active = c.in_progress ?? 0, blocked = c.blocked ?? 0;
  const out = [];
  for (let i = 0; i < total; i++) {
    out.push(i < closed ? "closed" : i < closed + active ? "active" : i < closed + active + blocked ? "blocked" : "open");
  }
  return out;
}

export function levels(tasks) {
  const ids = new Set(tasks.map((t) => t.id));
  const edges = [];
  const preds = new Map(tasks.map((t) => [t.id, []]));
  for (const t of tasks) {
    for (const b of t.blocks ?? []) {
      if (!ids.has(b.id) || b.id === t.id) continue;
      edges.push({ from: t.id, to: b.id });
      preds.get(b.id).push(t.id);
    }
  }
  const depth = new Map();
  const walk = (id, trail) => {
    if (depth.has(id)) return depth.get(id);
    // A cycle is a malformed graph: the edge that closes it counts for nothing.
    if (trail.has(id)) return -1;
    trail.add(id);
    const d = 1 + Math.max(-1, ...preds.get(id).map((p) => walk(p, trail)));
    trail.delete(id);
    depth.set(id, d);
    return d;
  };
  for (const t of tasks) walk(t.id, new Set());
  const width = Math.max(0, ...depth.values()) + 1;
  const cols = Array.from({ length: tasks.length ? width : 0 }, () => []);
  const order = new Map(tasks.map((t, i) => [t.id, i]));
  for (const t of tasks) cols[depth.get(t.id)].push(t.id);
  // Barycenter: sit near the prerequisites, so connectors cross less. Ties keep the bead order.
  const row = new Map();
  cols.forEach((ids2, c) => {
    if (c > 0) {
      const mean = (id) => {
        const ps = preds.get(id).filter((p) => row.has(p));
        return ps.length ? ps.reduce((s, p) => s + row.get(p), 0) / ps.length : Infinity;
      };
      ids2.sort((a, b) => (mean(a) - mean(b)) || (order.get(a) - order.get(b)) || 0);
    }
    ids2.forEach((id, i) => row.set(id, i));
  });
  return { cols, col: new Map([...depth]), edges };
}

export function place(tasks, sizes) {
  const { card, gap, pad, head, heightOf, rowGap } = sizes;
  const byId = new Map(tasks.map((t) => [t.id, t]));
  const { cols, col, edges } = levels(tasks);
  const nodes = new Map();
  let height = 0;
  cols.forEach((ids, c) => {
    let y = pad + head;
    ids.forEach((id, r) => {
      const h = heightOf(byId.get(id));
      nodes.set(id, { x: pad + c * (card + gap), y, w: card, h, col: c, row: r });
      y += h + rowGap;
    });
    height = Math.max(height, y - rowGap + pad);
  });
  const width = cols.length ? pad * 2 + cols.length * card + (cols.length - 1) * gap : 0;
  return { nodes, width, height: Math.max(height, cols.length ? pad * 2 + head : 0), cols, col, edges };
}

export function elbow(a, b, r = 6) {
  const dy = Math.abs(b.y - a.y), dx = b.x - a.x;
  if (dx <= 0) return [];
  if (dy === 0) return [{ x: a.x, y: a.y, w: dx, h: 1 }];
  // The turn happens in the middle of the gap before b (28 px or less).
  const mx = Math.round(b.x - Math.min(dx, 28) / 2);
  const rr = Math.max(0, Math.min(r, Math.floor(dy / 2), mx - a.x, b.x - mx - 1));
  const down = b.y > a.y;
  const out = [];
  if (mx - rr > a.x) out.push({ x: a.x, y: a.y, w: mx - rr - a.x, h: 1 });
  if (rr === 0) {
    out.push({ x: mx, y: Math.min(a.y, b.y), w: 1, h: dy + 1 });
  } else if (down) {
    out.push({ x: mx - rr, y: a.y, w: rr + 1, h: rr, corner: "tr", r: rr });
    if (dy - 2 * rr > 0) out.push({ x: mx, y: a.y + rr, w: 1, h: dy - 2 * rr });
    out.push({ x: mx, y: b.y - rr, w: rr + 1, h: rr + 1, corner: "bl", r: rr });
  } else {
    out.push({ x: mx - rr, y: a.y - rr + 1, w: rr + 1, h: rr, corner: "br", r: rr });
    if (dy - 2 * rr > 0) out.push({ x: mx, y: b.y + rr + 1, w: 1, h: dy - 2 * rr });
    out.push({ x: mx, y: b.y, w: rr + 1, h: rr + 1, corner: "tl", r: rr });
  }
  if (b.x > mx + rr + 1) out.push({ x: mx + rr + 1, y: b.y, w: b.x - (mx + rr + 1), h: 1 });
  return out;
}

const isLive = (t) => (t.state ?? "live") === "live";

// A terminal's word, as tasks.js reads it: the agents() word, else the core's; a finished one is failed or ended.
function termWord(t, listed) {
  if (!isLive(t)) return t.exit_code ? "failed" : "ended";
  const own = listed?.get?.(t.address);
  if (own) return own === "error" ? "blocked" : own;
  const s = typeof t.status === "string" ? t.status : t.status?.state ?? t.report?.state;
  return s === "error" ? "blocked" : s || "working";
}

// `byName`: a name may find the terminal. A closed review round's may not: the skill reuses r-<stem> across rounds,
// so the name now belongs to a later round's session.
function resolve(name, address, { terms = [], listed, hibernated = [] }, byName = true) {
  const live = terms.filter(isLive);
  const named = byName && name;
  const term = (address && live.find((t) => t.address === address)) || (named && live.find((t) => t.name === name)) || null;
  if (term) return { state: termWord(term, listed), term, hib: null, address: term.address };
  const hib = hibernated.find((h) => (named && h.name === name) || (address && h.address === address)) ?? null;
  if (hib) return { state: "hibernated", term: null, hib, address: hib.address ?? address ?? null };
  const dead = terms.find((t) => !isLive(t) && ((address && t.address === address) || (named && t.name === name))) ?? null;
  if (dead) return { state: termWord(dead, listed), term: dead, hib: null, address: dead.address };
  return { state: "gone", term: null, hib: null, address: address ?? null };
}

export function sessionsOf(task, ctx = {}) {
  // One worker row per name, with its newest address (a restart keeps the name); one reviewer row per round (the
  // skill reuses r-<stem> across rounds). Map order is the order of the newest mention, newest last.
  const rows = new Map();
  const add = (key, name, address, role, round, program, byName = true) => {
    if (!name) return;
    const r = resolve(name, address, ctx, byName);
    const resume = r.term?.labels?.resume || r.hib?.line || null;
    rows.delete(key);
    rows.set(key, { name, role, round, address: r.address, state: r.state, term: r.term, program: r.term?.program ?? r.hib?.program ?? program ?? null, resume });
  };
  for (const e of task.events ?? []) {
    if (!["dispatched", "handed-off", "adopted"].includes(e.name)) continue;
    const agent = e.fields.agent ?? "";
    if (/^w-/.test(agent)) add(agent, agent, e.fields.terminal, "worker", 0);
  }
  if (task.worker) add(task.worker.name, task.worker.name, task.worker.address, "worker", 0, task.worker.term?.program);
  for (const rv of task.reviewers ?? []) {
    const name = rv.bead?.assignee || rv.worker?.name;
    // A closed round keeps its own history: the terminal its own events named, never a later round's by name.
    const own = [...(rv.events ?? [])].reverse().find((e) => e.fields?.terminal)?.fields.terminal;
    add(`${name}#${rv.round}`, name, rv.worker?.address ?? own, "reviewer", rv.round, rv.worker?.term?.program, rv.open !== false);
  }
  return [...rows.values()];
}

export function driftOf(events) {
  for (let i = (events?.length ?? 0) - 1; i >= 0; i--) {
    const e = events[i];
    if (e.name === "note" && /^remote body changed/i.test(e.fields.detail ?? "")) return { at: e.at, text: e.fields.detail };
  }
  return null;
}

export function pickDefault(tasks) {
  return (tasks.find((t) => t.turn === "you") ?? tasks.find((t) => t.turn === "worker")
    ?? tasks.find((t) => t.turn === "orch") ?? tasks.find((t) => t.turn !== "done") ?? tasks[0])?.id ?? null;
}

export function graphStep(graph, id, dir) {
  const here = graph.nodes.get(id);
  if (!here) return id;
  if (dir === "up" || dir === "down") {
    return graph.cols[here.col][here.row + (dir === "down" ? 1 : -1)] ?? id;
  }
  const next = graph.cols[here.col + (dir === "right" ? 1 : -1)];
  if (!next?.length) return id;
  const mid = here.y + here.h / 2;
  let best = next[0], gap = Infinity;
  for (const n of next) {
    const b = graph.nodes.get(n);
    const d = Math.abs(b.y + b.h / 2 - mid);
    if (d < gap) { best = n; gap = d; }
  }
  return best;
}

export function parseKey(e) {
  const m = e?.modifiers ?? {};
  if (m.control || m.alt || m.platform) return null;
  if (e.key === "tab") return m.shift ? "shift-tab" : "tab";
  return ["up", "down", "left", "right", "enter", "escape"].includes(e.key) ? e.key : null;
}

export function shortPath(path, home) {
  const h = String(home ?? "").replace(/\/+$/, "");
  return h && path && (path === h || path.startsWith(`${h}/`)) ? `~${path.slice(h.length)}` : path;
}
