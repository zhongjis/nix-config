// One vocabulary for every agent surface (Agents panel, rail, popup, beads view). Pure: imports nothing.
//
// API
//   AGENT_WORDS                  { working, blocked, done, idle, hibernated, ended, failed } -> word
//   agentWord(status)            "working" -> "Working", "blocked" -> "Needs you"; an unknown status is
//                                capitalized as given, a missing one is "".
//   TURN_WORDS                   { worker, orch, you, waiting, slot, queued } -> word ("waiting" is "Waits on").
//   turnWord(task)               The turn chip text of a task row (tasks.js buildTasks): task.turn through
//                                TURN_WORDS; "waiting" -> "Waits on ABC-12" (first of task.waitsOn); "done" -> the
//                                settle result ("Succeeded", "Failed", "Abandoned", "Blocked", "Uncertain", or
//                                "Closed" for a bead closed without a settle event),
//                                "Merged, releasing" before the task is settled.
//   RESULT_WORDS                 settle result -> word.
//   REPORT_WORDS / reportWord(kind)   report kinds (ready-local, pushed, pr-opened, blocked, done).
//   EVENT_WORDS / eventWord(name)     every name event.sh accepts, plus "report"; unknown names are returned as given.
//   REASON_WORDS / reasonWord(code)   reason codes as sentences; an unknown code is returned as given.
//   ago(at, now)                 Age of a timestamp (ms): "just now" under a minute, then "5m", "2h", "3d"
//                                (floored). "" for a missing timestamp. A bare duration: append " ago" to
//                                anything but "just now", or call agoText.
//   agoText(at, now)             ago() as a phrase: "just now", "5m ago", "2h ago", "3d ago".
//   took(from, to)               Duration between two timestamps (ms): "9s", "4m", "1h 5m", "2d 3h"
//                                (floored; a zero second unit is dropped: "1h", "2d"). "" when either is missing.

export const AGENT_WORDS = {
  working: "Working",
  blocked: "Needs you",
  done: "Done",
  idle: "Idle",
  hibernated: "Hibernated",
  ended: "Ended",
  failed: "Failed",
};

export const TURN_WORDS = {
  worker: "Worker's turn",
  orch: "Orchestrator's turn",
  you: "Your turn",
  waiting: "Waits on",
  slot: "Waiting for a slot",
  queued: "Queued",
};

export const RESULT_WORDS = {
  succeeded: "Succeeded",
  failed: "Failed",
  abandoned: "Abandoned",
  blocked: "Blocked",
  uncertain: "Uncertain",
  closed: "Closed",
};

export const REPORT_WORDS = {
  "ready-local": "Ready for local review",
  pushed: "Pushed",
  "pr-opened": "PR opened",
  blocked: "Blocked",
  done: "Done",
};

export const EVENT_WORDS = {
  mode: "Mode set",
  ticketed: "Ticket linked",
  dispatched: "Dispatched",
  "handed-off": "Handed off",
  queued: "Queued",
  "re-instructed": "Re-instructed",
  ready: "Ready",
  merged: "Merged",
  settled: "Settled",
  reaped: "Cleaned up",
  blocked: "Blocked",
  decided: "Decided",
  note: "Note",
  adopted: "Adopted",
  report: "Reported",
};

export const REASON_WORDS = {
  "needs-user": "Waiting on your answer",
  "remote-closed": "Ticket closed remotely",
  "pull-skipped": "Ticket pull skipped",
};

const capital = (s) => (s ? s[0].toUpperCase() + s.slice(1) : "");
const lookup = (table) => (key) => (Object.hasOwn(table, key) ? table[key] : (key ?? ""));

export const agentWord = (status) => (Object.hasOwn(AGENT_WORDS, status) ? AGENT_WORDS[status] : capital(status));
export const reportWord = lookup(REPORT_WORDS);
export const eventWord = lookup(EVENT_WORDS);
export const reasonWord = lookup(REASON_WORDS);

export function turnWord(task) {
  const turn = task?.turn;
  if (turn === "waiting") {
    const on = task.waitsOn?.[0];
    return on ? `${TURN_WORDS.waiting} ${on.key ?? on.id}` : TURN_WORDS.waiting;
  }
  if (turn === "done") {
    if (!task.life?.settled) return "Merged, releasing";
    return Object.hasOwn(RESULT_WORDS, task.life.result) ? RESULT_WORDS[task.life.result] : "Settled";
  }
  return Object.hasOwn(TURN_WORDS, turn) ? TURN_WORDS[turn] : "";
}

const MIN = 60000, HOUR = 3600000, DAY = 86400000;

export function ago(at, now) {
  if (!Number.isFinite(at) || at <= 0) return "";
  const d = now - at;
  if (d < MIN) return "just now";
  if (d < HOUR) return `${Math.floor(d / MIN)}m`;
  if (d < DAY) return `${Math.floor(d / HOUR)}h`;
  return `${Math.floor(d / DAY)}d`;
}

export function agoText(at, now) {
  const a = ago(at, now);
  return a && a !== "just now" ? `${a} ago` : a;
}

export function took(from, to) {
  if (!Number.isFinite(from) || !Number.isFinite(to)) return "";
  const d = Math.max(0, to - from);
  if (d < MIN) return `${Math.floor(d / 1000)}s`;
  if (d < HOUR) return `${Math.floor(d / MIN)}m`;
  const pair = (big, bigMs, small, smallMs) => {
    const b = Math.floor(d / bigMs), s = Math.floor((d % bigMs) / smallMs);
    return s ? `${b}${big} ${s}${small}` : `${b}${big}`;
  };
  return d < DAY ? pair("h", HOUR, "m", MIN) : pair("d", DAY, "h", HOUR);
}
