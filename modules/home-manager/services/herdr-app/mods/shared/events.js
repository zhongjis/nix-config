// Bead events: the `event=<name> k=v ...` comments the orchestration skill writes on beads, and who held a task
// between them. Pure: imports nothing, so node tests load it.
//
// API
//   KNOWN_KEYS                   Every field key the orchestrator and worker skills write.
//   parseEvent(comment)          comment: { id?, text, created_at?, author? } (a `bd comments --json` entry).
//                                -> { id, name, fields, at, line, body, actor, author } or null for a plain comment.
//                                  id:     the comment's id (what a panel answer names as its question), or null.
//                                  name:   "dispatched", "report", ... (first line `event=<name> ...`)
//                                  fields: { key: value }; a field starts at `<key>=` when key is the first token or
//                                          a KNOWN_KEYS member after a space, and runs to the next start, so values keep
//                                          their spaces and an unknown `x=y` inside a value stays in it.
//                                          A value written quoted (`q="…"`, the skill's event.sh does it for a value
//                                          with a line break or tab, a leading `"`, or ` k=` inside) runs to its
//                                          closing `"` before a space or the line's end, with \\ \" \n \r \t
//                                          decoded; the next field then starts at the next `key=`. A `"` with no such
//                                          close reads as plain text, so older comments parse as they always did.
//                                  at:     created_at as epoch ms, or null.
//                                  line:   the first line; body: the rest, trimmed.
//                                  actor:  "orch" (author o-...), "worker" (w-...), "reviewer" (r-...), else "user".
//                                  author: the raw author.
//   eventsOf(comments)           parseEvent over a list, non-events dropped, oldest first (stable for equal times).
//   questionOf(event)            What a `blocked` event asks: its q= field, else its body (whole), else "".
//   holderAfter(event, prev)     Who holds the task after `event`: "worker" | "orch" | "you" | "done".
//                                dispatched, re-instructed -> worker; report -> orch; blocked -> you when
//                                fields.reason is needs-user, else orch; decided, ready, merged -> orch;
//                                settled -> done; reaped keeps done and a question waiting on you, else orch (the
//                                task is still open);
//                                any other keeps `prev` (orch when there is none yet).
//   rounds(events)               [{ n, at, events }]: a round starts at each dispatched or re-instructed (n = 1, 2, ...);
//                                events before the first form round 0 (left out when empty). `at`: its first event's time.
//   held(events, now)            { spans, totals }. spans: one per event { event, holder, from, to, ms }, the span
//                                running until the next event (the last until `now`; ms 0 without times). A span
//                                held as "done" ends where it starts, so a settled task's time stops growing.
//                                totals: { worker, orch, you } ms; time held as "done" is not counted.

export const KNOWN_KEYS = [
  "agent", "terminal", "worktree", "kind", "result", "head", "pr", "reason", "by", "q", "a", "detail",
  "merged_sha", "flags", "max", "needs", "round", "bead", "last-reviewed", "stopped", "run", "bot_rounds",
  "after", "handoff", "tab", "session", "question", "reviewer", "model",
];

const KEY = "[a-z][a-z0-9_-]*";

const ESCAPES = { "\\": "\\", '"': '"', n: "\n", r: "\r", t: "\t" };

// A quoted value at `from` (tail[from] is `"`): { value, end } when it closes before a space or the end, else null.
function quoted(tail, from) {
  let value = "";
  for (let i = from + 1; i < tail.length; i++) {
    const ch = tail[i];
    if (ch === "\\" && i + 1 < tail.length) { value += ESCAPES[tail[i + 1]] ?? tail[i + 1]; i++; continue; }
    if (ch === '"') return i + 1 === tail.length || tail[i + 1] === " " ? { value, end: i + 1 } : null;
    value += ch;
  }
  return null;
}

export function parseEvent(comment) {
  const [first = "", ...rest] = String(comment?.text ?? "").split("\n");
  const m = new RegExp(`^event=(${KEY})(?: |$)`).exec(first);
  if (!m) return null;
  const tail = first.slice(m[0].length);
  const anyKey = new RegExp(`^(${KEY})=`), known = new RegExp(` (${KEY})=`, "g");
  // The next field start at or after `pos`: any key right at `pos` when `head` (the first token, or after a quoted
  // value), else a known key after a space.
  const next = (pos, head) => {
    if (head) {
      const h = anyKey.exec(tail.slice(pos));
      if (h) return { key: h[1], at: pos, from: pos + h[0].length };
    }
    known.lastIndex = Math.max(0, pos - 1);
    for (let s = known.exec(tail); s; s = known.exec(tail)) {
      if (s.index >= pos - 1 && KNOWN_KEYS.includes(s[1])) return { key: s[1], at: s.index, from: s.index + s[0].length };
    }
    return null;
  };
  const fields = {};
  let cur = next(0, true);
  while (cur) {
    const q = tail[cur.from] === '"' ? quoted(tail, cur.from) : null;
    if (q) {
      fields[cur.key] = q.value;
      const after = tail.slice(q.end).match(/^ +/)?.[0].length ?? 0;
      cur = next(q.end + after, true);
      continue;
    }
    const n = next(cur.from, false);
    fields[cur.key] = tail.slice(cur.from, n?.at ?? tail.length).trim();
    cur = n;
  }
  const at = Date.parse(comment?.created_at ?? "");
  const author = String(comment?.author ?? "");
  const actor = author.startsWith("o-") ? "orch" : author.startsWith("w-") ? "worker" : author.startsWith("r-") ? "reviewer" : "user";
  return { id: comment?.id ?? null, name: m[1], fields, at: Number.isNaN(at) ? null : at, line: first, body: rest.join("\n").trim(), actor, author };
}

export function eventsOf(comments) {
  const out = [];
  for (const c of comments ?? []) {
    const e = parseEvent(c);
    if (e) out.push(e);
  }
  return out.sort((a, b) => (a.at ?? 0) - (b.at ?? 0));
}

export const questionOf = (e) => e?.fields?.q || e?.body || "";

export function holderAfter(event, prev) {
  switch (event.name) {
    case "dispatched":
    case "re-instructed":
      return "worker";
    case "report":
    case "decided":
    case "ready":
    case "merged":
      return "orch";
    case "blocked":
      return event.fields.reason === "needs-user" ? "you" : "orch";
    case "settled":
      return "done";
    case "reaped":
      // Cleanup changes nothing about an open question: it stays yours until it is decided.
      return prev === "done" || prev === "you" ? prev : "orch";
    default:
      return prev ?? "orch";
  }
}

export function rounds(events) {
  const out = [];
  let cur = null;
  for (const e of events) {
    if (e.name === "dispatched" || e.name === "re-instructed") {
      cur = { n: out.filter((r) => r.n > 0).length + 1, at: e.at, events: [] };
      out.push(cur);
    } else if (!cur) {
      cur = { n: 0, at: e.at, events: [] };
      out.push(cur);
    }
    cur.events.push(e);
  }
  return out;
}

export function held(events, now) {
  const spans = [];
  const totals = { worker: 0, orch: 0, you: 0 };
  let holder;
  events.forEach((event, i) => {
    holder = holderAfter(event, holder);
    const from = event.at;
    const to = events[i + 1] ? events[i + 1].at : now;
    const end = holder === "done" ? from : to;
    const ms = from != null && end != null ? Math.max(0, end - from) : 0;
    spans.push({ event, holder, from, to: end, ms });
    if (holder in totals) totals[holder] += ms;
  });
  return { spans, totals };
}
