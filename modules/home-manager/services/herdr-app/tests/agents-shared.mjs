// Shared agent modules (mods/shared): words, bead events, tasks and the change clock, on made-up generic data.
// name.js imports "herdr", so its import line is dropped to test termName here. bd.js needs herdr and isn't loaded.
// Run: node modules/home-manager/services/herdr-app/tests/agents-shared.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { Clock } from "../mods/shared/clock.js";
import { KNOWN_KEYS, eventsOf, held, holderAfter, parseEvent, questionOf, rounds } from "../mods/shared/events.js";
import { buildTasks, lifecycle, sourceLabel, summary, taskKey, turnOf } from "../mods/shared/tasks.js";
import { agentWord, ago, agoText, eventWord, reasonWord, reportWord, took, turnWord, EVENT_WORDS } from "../mods/shared/words.js";

const nameSrc = readFileSync(new URL("../mods/shared/name.js", import.meta.url), "utf8").replace(/^import .*$/m, "");
const { termName } = await import(`data:text/javascript;base64,${Buffer.from(nameSrc).toString("base64")}`);

const T0 = Date.parse("2026-01-01T00:00:00Z");
const at = (min) => new Date(T0 + min * 60000).toISOString();
/** @param {string} text @param {number} min @param {string} author */
const c = (text, min, author = "o-t9") => ({ text, created_at: at(min), author });

// name.js: termName
const ask = (k) => `asked:${k.address}`;
assert.equal(termName({ address: "t3", name: "w-abc-12-keys" }, ask), "w-abc-12-keys");
assert.equal(termName({ address: "t3" }, ask), "asked:t3");
assert.equal(termName({ address: "t3", name: "w-abc-12-keys" }, ask, new Set(["t3"])), "asked:t3");
assert.equal(termName({ address: "t3", name: "w-abc-12-keys", pane_name: null }, ask), "asked:t3");

// words
assert.equal(agentWord("blocked"), "Needs you");
assert.equal(agentWord("supervising"), "Supervising");
assert.equal(reportWord("pr-opened"), "PR opened");
assert.equal(reasonWord("needs-user"), "Waiting on your answer");
assert.equal(reasonWord("odd"), "odd");
for (const n of ["mode", "ticketed", "dispatched", "handed-off", "queued", "re-instructed", "ready", "merged", "settled", "reaped", "blocked", "decided", "note", "adopted"]) {
  assert.ok(Object.hasOwn(EVENT_WORDS, n), n);
}
assert.equal(eventWord("nope"), "nope");
// ago / took boundaries
const now = T0 + 10 * 86400000;
assert.equal(ago(now - 59999, now), "just now");
assert.equal(ago(now - 60000, now), "1m");
assert.equal(ago(now - 3599000, now), "59m");
assert.equal(ago(now - 3600000, now), "1h");
assert.equal(ago(now - 86399000, now), "23h");
assert.equal(ago(now - 86400000, now), "1d");
assert.equal(ago(now + 5000, now), "just now");
assert.equal(ago(0, now), "");
assert.equal(agoText(now - 1000, now), "just now");
assert.equal(agoText(now - 5 * 60000, now), "5m ago");
assert.ok(!/now ago/.test([1000, 120000, 7200000, 300000000].map((d) => agoText(now - d, now)).join()));
assert.equal(took(0, 9000), "9s");
assert.equal(took(0, 59999), "59s");
assert.equal(took(0, 4 * 60000 + 30000), "4m");
assert.equal(took(0, 65 * 60000), "1h 5m");
assert.equal(took(0, 3600000), "1h");
assert.equal(took(0, 51 * 3600000), "2d 3h");
assert.equal(took(0, 48 * 3600000), "2d");
assert.equal(took(null, 5), "");

// events: parseEvent
const dec = parseEvent(c("event=decided q=Keep the old API? a=no, add a flag instead by=user\n\nbody line one\nline two", 5));
assert.deepEqual(dec.fields, { q: "Keep the old API?", a: "no, add a flag instead", by: "user" });
assert.deepEqual([dec.name, dec.actor, dec.at, dec.body], ["decided", "orch", T0 + 5 * 60000, "body line one\nline two"]);
assert.equal(dec.line, "event=decided q=Keep the old API? a=no, add a flag instead by=user");
// an unknown key inside a value stays in the value; an unknown first-token key is a field
assert.equal(parseEvent(c("event=note detail=remote body changed foo=bar baz", 0)).fields.detail, "remote body changed foo=bar baz");
assert.deepEqual(parseEvent(c("event=note foo=bar baz", 0)).fields, { foo: "bar baz" });
assert.deepEqual(parseEvent(c("event=queued", 0)).fields, {});
assert.deepEqual(parseEvent(c("event=queued needs=slot", 0)).fields, { needs: "slot" });
assert.equal(parseEvent({ text: "just a note" }), null);
assert.equal(parseEvent(null), null);
assert.equal(parseEvent(c("event=report kind=done", 0, "w-abc-12-keys")).actor, "worker");
assert.equal(parseEvent(c("event=report kind=done", 0, "r-abc-12-rev")).actor, "reviewer");
assert.equal(parseEvent(c("event=blocked reason=needs-user", 0, "someone")).actor, "user");
assert.equal(parseEvent({ text: "event=ready" }).at, null);
for (const k of ["agent", "merged_sha", "last-reviewed", "bot_rounds", "session", "handoff", "question", "reviewer", "model"]) assert.ok(KNOWN_KEYS.includes(k), k);
// A comment's id is the event's: a panel answer names the question it answers by it.
assert.equal(parseEvent({ id: "c-7", text: "event=blocked reason=needs-user" }).id, "c-7");
assert.equal(parseEvent({ text: "event=blocked" }).id, null);
// supervise.md's reviewer note keeps both fields.
assert.deepEqual(parseEvent(c("event=note reviewer=codex model=gpt-x", 0)).fields, { reviewer: "codex", model: "gpt-x" });

// Prose with field-like text: bare, a known ` k=` splits it (as it always did); quoted by event.sh, it stays whole.
assert.deepEqual(parseEvent(c("event=decided by=user q=Use by=default for new keys? a=yes", 0)).fields,
  { by: "default for new keys?", q: "Use", a: "yes" }, "the old split, kept for old comments");
const quotedQ = parseEvent(c('event=decided by=user q="Use by=default for new keys?" a="yes, and a=b too"', 0));
assert.deepEqual(quotedQ.fields, { by: "user", q: "Use by=default for new keys?", a: "yes, and a=b too" });
// Multi-line and quoted text, escaped the way event.sh writes it.
const multi = parseEvent(c('event=blocked reason=needs-user q="Which one?\\nA: \\"keep\\"\\tB: drop\\\\" agent=w-a', 0));
assert.deepEqual(multi.fields, { reason: "needs-user", q: 'Which one?\nA: "keep"\tB: drop\\', agent: "w-a" });
assert.equal(questionOf(multi), 'Which one?\nA: "keep"\tB: drop\\');
assert.equal(questionOf(parseEvent(c("event=blocked reason=needs-user\n\nLine one\nline two", 0))), "Line one\nline two");
// A quote that never closes (or closes mid-word) is plain text: old comments read as before.
assert.deepEqual(parseEvent(c('event=note detail="half open by=user', 0)).fields, { detail: '"half open', by: "user" });
assert.deepEqual(parseEvent(c('event=note detail="a"b by=user', 0)).fields, { detail: '"a"b', by: "user" });
assert.deepEqual(parseEvent(c('event=note detail="" by=user', 0)).fields, { detail: "", by: "user" });

// A recorded task: dispatched, worker reports, orchestrator re-instructs, worker blocks on a question, user answers
const log = eventsOf([
  c("event=report kind=pushed head=bbb", 40, "w-abc-12-keys"),
  c("event=dispatched agent=w-abc-12-keys terminal=t4 worktree=/w/abc-12", 0),
  c("plain comment", 1),
  c("event=report kind=ready-local head=aaa", 20, "w-abc-12-keys"),
  c("event=re-instructed agent=w-abc-12-keys", 30),
  c("event=blocked reason=needs-user\n\nShip the flag?", 50),
  c("event=decided q=Ship the flag? a=yes by=user", 110),
  c("event=ready head=ccc pr=https://example.test/o/r/pull/7", 120),
]);
assert.deepEqual(log.map((e) => e.name), ["dispatched", "report", "re-instructed", "report", "blocked", "decided", "ready"]);
assert.equal(holderAfter(log[0], undefined), "worker");
assert.equal(holderAfter(log[1], "worker"), "orch");
assert.equal(holderAfter(log[4], "worker"), "you");
assert.equal(holderAfter({ name: "blocked", fields: { reason: "other" } }, "worker"), "orch");
assert.equal(holderAfter({ name: "decided", fields: {} }, "you"), "orch");
assert.equal(holderAfter({ name: "ready", fields: {} }, "worker"), "orch");
assert.equal(holderAfter({ name: "merged", fields: {} }, "worker"), "orch");
assert.equal(holderAfter({ name: "settled", fields: {} }, "orch"), "done");
// Reaped ends the worker, not the task: settled, it stays done; still open, it is the orchestrator's.
assert.equal(holderAfter({ name: "reaped", fields: {} }, "done"), "done");
assert.equal(holderAfter({ name: "reaped", fields: {} }, "orch"), "orch");
assert.equal(holderAfter({ name: "reaped", fields: {} }, "you"), "you", "an open question stays yours through cleanup");
assert.equal(holderAfter({ name: "note", fields: {} }, "you"), "you");
assert.equal(holderAfter({ name: "note", fields: {} }, undefined), "orch");

const h = held(log, T0 + 130 * 60000);
assert.deepEqual(h.spans.map((s) => [s.holder, s.ms / 60000]), [["worker", 20], ["orch", 10], ["worker", 10], ["orch", 10], ["you", 60], ["orch", 10], ["orch", 10]]);
assert.deepEqual(h.totals, { worker: 30 * 60000, orch: 40 * 60000, you: 60 * 60000 });
assert.equal(held([{ name: "settled", at: 0, fields: {} }], 99999).totals.orch, 0);
assert.equal(held([{ name: "settled", at: 0, fields: {} }], 99999).spans[0].holder, "done");
// A settled task's time stops at the settle: its last span doesn't grow with `now`.
const settledLog = eventsOf([c("event=dispatched agent=w-a", 0), c("event=settled result=succeeded", 10), c("event=reaped stopped=worker", 12)]);
assert.deepEqual(held(settledLog, T0 + 9999 * 60000).spans.map((x) => [x.holder, x.ms / 60000]), [["worker", 10], ["done", 0], ["done", 0]]);
// A worker reaped while the task stays open hands it back to the orchestrator, whose time keeps counting.
const reapedOpen = eventsOf([c("event=dispatched agent=w-a", 0), c("event=reaped stopped=worker", 10)]);
assert.deepEqual(held(reapedOpen, T0 + 30 * 60000).totals, { worker: 10 * 60000, orch: 20 * 60000, you: 0 });
// Late-round history: rounds after the first keep their own events.
const late3 = rounds(eventsOf([c("event=dispatched agent=w-a", 0), c("event=re-instructed agent=w-a", 5), c("event=report kind=done", 6, "w-a"),
  c("event=re-instructed agent=w-a", 9), c("event=report kind=pushed", 12, "w-a")]));
assert.deepEqual(late3.map((r) => [r.n, r.events.length]), [[1, 1], [2, 2], [3, 2]]);

const rs = rounds(log);
assert.deepEqual(rs.map((r) => [r.n, r.events.map((e) => e.name)]), [[1, ["dispatched", "report"]], [2, ["re-instructed", "report", "blocked", "decided", "ready"]]]);
const early = rounds(eventsOf([c("event=ticketed", 0), c("event=dispatched agent=w-x", 1)]));
assert.deepEqual(early.map((r) => r.n), [0, 1]);

// taskKey
assert.equal(taskKey({ id: "b-1", external_ref: "https://tracker.example/team/issue/abc-12/some-slug" }), "ABC-12");
assert.equal(taskKey({ id: "b-1", external_ref: "https://jira.example/browse/ABC-12" }), "ABC-12");
assert.equal(taskKey({ id: "b-1", external_ref: "https://example.test/x/ABC-12" }), "ABC-12");
assert.equal(taskKey({ id: "b-1", metadata: { key: "abc-9" } }), "ABC-9");
assert.equal(taskKey({ id: "b-1" }), "b-1");

// lifecycle: every stop
const life = (bead, comments, reviews) => lifecycle({ id: "b", metadata: {}, ...bead }, eventsOf(comments), reviews);
assert.equal(life({}, []).stop, 0);
assert.equal(life({}, [c("event=dispatched agent=w-a", 0)]).stop, 1);
assert.equal(life({}, [c("event=handed-off agent=w-a", 0)]).stop, 1);
assert.equal(life({}, [c("event=adopted agent=w-a", 0)]).stop, 1);
assert.equal(life({ metadata: { review_round: "1" } }, [c("event=dispatched agent=w-a", 0)]).stop, 2);
assert.equal(life({}, [c("event=dispatched agent=w-a", 0)], [{ id: "r1" }]).stop, 2);
assert.equal(life({ metadata: { pr_url: "https://example.test/pull/1" } }, []).stop, 3);
assert.equal(life({}, [c("event=report kind=pr-opened head=a pr=https://example.test/pull/2", 5, "w-a")]).pr, "https://example.test/pull/2");
assert.equal(life({}, [c("event=report kind=pr-opened head=a pr=https://example.test/pull/2", 5, "w-a")]).stop, 3);
const readyLife = life({}, [c("event=report kind=pushed head=a", 1, "w-a"), c("event=ready head=b pr=https://example.test/pull/2", 2)]);
assert.deepEqual([readyLife.stop, readyLife.ready, readyLife.head], [4, true, "b"]);
assert.equal(life({}, [c("event=ready head=b", 1), c("event=report kind=pushed head=c", 2, "w-a")]).ready, false);
assert.equal(life({ metadata: { merged_sha: "0".repeat(40) } }, []).stop, 5);
assert.equal(life({}, [c("event=merged merged_sha=" + "1".repeat(40), 1)]).merged, true);
const settledLife = life({}, [c("event=merged merged_sha=" + "1".repeat(40), 1), c("event=settled result=failed", 2)]);
assert.deepEqual([settledLife.stop, settledLife.settled, settledLife.result], [6, true, "failed"]);
assert.equal(life({ status: "blocked" }, []).hold, "blocked");
const held1 = life({ metadata: { blocked_reason: "needs-user" } }, [c("event=blocked reason=needs-user\n\nShip the flag?\nmore", 1), c("event=blocked reason=needs-user\n\nWhich branch?", 2)]);
assert.deepEqual([held1.hold, held1.holdQuestion], ["needs-user", "Which branch?"]);
// The whole question (a multi-line body), and the comment it came from.
const held2 = lifecycle({ id: "b", metadata: { blocked_reason: "needs-user" } },
  eventsOf([{ id: "q-1", text: "event=blocked reason=needs-user\n\nShip the flag?\nIt doubles the size.", created_at: at(1), author: "o-t9" }]));
assert.deepEqual([held2.holdQuestion, held2.holdQuestionId], ["Ship the flag?\nIt doubles the size.", "q-1"]);
assert.equal(lifecycle({ id: "b", metadata: {} }, eventsOf([c('event=blocked reason=needs-user q="Pick one?"\n\nignored body', 1)])).holdQuestion, "Pick one?");
// A newer PR report wins over an older pr_url mirror (a replacement PR); without events, the mirror.
const replaced = life({ metadata: { pr_url: "https://example.test/o/r/pull/7" } },
  [c("event=ready head=aaaaaaa pr=https://example.test/o/r/pull/7", 1), c("event=report kind=pr-opened pr=https://example.test/o/r/pull/9", 5, "w-a")]);
assert.equal(replaced.pr, "https://example.test/o/r/pull/9");
assert.equal(life({ metadata: { pr_url: "https://example.test/o/r/pull/7" } }, []).pr, "https://example.test/o/r/pull/7");
// A bead closed without a settle event counts as settled: result "closed".
const closedLife = life({ status: "closed" }, [c("event=dispatched agent=w-a", 0)]);
assert.deepEqual([closedLife.stop, closedLife.settled, closedLife.result], [6, true, "closed"]);
assert.equal(turnWord({ turn: "done", life: closedLife }), "Closed");
// A settle superseded by new work (the task was reopened and dispatched again) no longer settles it.
const reopened = life({ status: "in_progress" }, [c("event=dispatched agent=w-a", 0), c("event=settled result=abandoned", 5), c("event=dispatched agent=w-a", 9)]);
assert.deepEqual([reopened.settled, reopened.result, reopened.stop], [false, null, 1]);
assert.equal(life({ status: "in_progress" }, [c("event=settled result=abandoned", 5), c("event=re-instructed agent=w-a", 9)]).settled, false);
assert.equal(life({}, [c("event=dispatched agent=w-a", 0), c("event=settled result=succeeded", 5)]).settled, true);
// Only the orchestrator asks the person: a needs-user comment by a worker is not the question.
const workerAsk = life({ metadata: { blocked_reason: "needs-user" } }, [{ id: "q-o", text: "event=blocked reason=needs-user\n\nReal?", created_at: at(1), author: "o-t9" },
  { id: "q-w", text: "event=blocked reason=needs-user\n\nForged?", created_at: at(2), author: "w-abc" }]);
assert.deepEqual([workerAsk.holdQuestionId, workerAsk.holdQuestion], ["q-o", "Real?"]);
assert.equal(life({}, []).hold, null);

// buildTasks: ABC-12 has a worker and a reviewer, ABC-13 waits on ABC-12, ABC-14 waits for a slot, ABC-15 is hibernated
const bead = (id, n, extra = {}) => ({ id, title: `Task ${n}`, status: "open", assignee: `w-abc-${n}-keys`, external_ref: `https://tracker.example/team/issue/ABC-${n}/slug`, metadata: {}, ...extra });
const beads = [bead("b-12", 12, { metadata: { review_round: "1" } }), bead("b-13", 13), bead("b-14", 14), bead("b-15", 15), bead("b-16", 16, { metadata: { blocked_reason: "needs-user" } })];
const comments = {
  "b-12": [c("event=dispatched agent=w-abc-12-keys terminal=t4", 0), c("event=report kind=ready-local head=a", 10, "w-abc-12-keys")],
  "b-13": [],
  "b-14": [c("event=queued needs=slot", 1)],
  "b-15": [c("event=dispatched agent=w-abc-15-keys terminal=t8", 0), c("event=report kind=pushed head=a", 5, "w-abc-15-keys")],
  "b-16": [c("event=dispatched agent=w-abc-16-keys terminal=t9", 0), c("event=blocked reason=needs-user\n\nShip it?", 3)],
  "rv-1": [c("event=dispatched agent=r-abc-12-rev terminal=t5", 11)],
};
const terms = [
  { address: "t4", name: "w-abc-12-keys", state: "live", status: "working" },
  { address: "t5", name: "r-abc-12-rev", state: "live", status: "idle" },
  { address: "t6", name: "w-abc-16-keys", state: "live", status: "blocked" },
  { address: "t7", name: "w-abc-14-keys", state: "live", status: "idle" },
];
const input = {
  epic: { id: "ep-1" },
  beads: [{ id: "ep-1" }, ...beads],
  deps: { "b-13": [{ id: "b-12", type: "blocks" }, { id: "ep-1", type: "parent-child" }], "b-12": [{ id: "b-ext", type: "blocks", status: "closed" }] },
  reviews: { "b-12": [{ id: "rv-1", title: "Review round 1", assignee: "r-abc-12-rev", status: "closed" }, { id: "x", title: "Other", assignee: "w-q" }] },
  comments,
  terms,
  listed: new Map([["t4", "working"], ["t6", "blocked"]]),
  hibernated: [{ name: "w-abc-15-keys", address: "t8", line: "pi --session s1" }],
  now: T0 + 60 * 60000,
};
const tasks = buildTasks(input);
const by = Object.fromEntries(tasks.map((t) => [t.key, t]));
assert.deepEqual(tasks.map((t) => t.key), ["ABC-12", "ABC-13", "ABC-14", "ABC-15", "ABC-16"]);
assert.equal(by["ABC-12"].url, "https://tracker.example/team/issue/ABC-12/slug");
assert.deepEqual([by["ABC-12"].worker.name, by["ABC-12"].worker.address, by["ABC-12"].worker.status], ["w-abc-12-keys", "t4", "working"]);
assert.deepEqual(by["ABC-12"].reviewers.map((r) => [r.bead.id, r.round, r.worker.address, r.worker.status]), [["rv-1", 1, "t5", "idle"]]);
assert.equal(by["ABC-12"].life.stop, 2);
assert.deepEqual(by["ABC-12"].waitsOn, []);
assert.deepEqual(by["ABC-12"].blocks, [{ id: "b-13", key: "ABC-13" }]);
assert.deepEqual(by["ABC-13"].waitsOn, [{ id: "b-12", key: "ABC-12", status: "open" }]);
assert.equal(by["ABC-13"].worker, null);
assert.equal(by["ABC-14"].worker.address, "t7");
assert.equal(by["ABC-14"].slotWait, true);
assert.deepEqual([by["ABC-15"].worker.status, by["ABC-15"].worker.hibernated.line], ["hibernated", "pi --session s1"]);
assert.equal(by["ABC-12"].since, T0 + 10 * 60000);
// turns
assert.deepEqual(tasks.map((t) => t.turn), ["worker", "waiting", "slot", "orch", "you"]);
assert.equal(turnWord(by["ABC-13"]), "Waits on ABC-12");
assert.equal(turnWord(by["ABC-14"]), "Waiting for a slot");
assert.equal(turnWord(by["ABC-12"]), "Worker's turn");
assert.equal(turnWord(by["ABC-16"]), "Your turn");
assert.equal(by["ABC-16"].life.holdQuestion, "Ship it?");
// a closed prerequisite no longer holds a task
const closedDeps = buildTasks({ ...input, beads: [{ id: "ep-1" }, ...beads.map((b) => (b.id === "b-12" ? { ...b, status: "closed" } : b))] });
assert.deepEqual(closedDeps.find((t) => t.key === "ABC-13").waitsOn, []);
// the other turns
const base = { life: { settled: false, hold: null, merged: false, stop: 1 }, worker: null, waitsOn: [], slotWait: false, events: [] };
assert.equal(turnOf({ ...base, life: { ...base.life, settled: true } }), "done");
assert.equal(turnOf({ ...base, life: { ...base.life, merged: true } }), "orch");
assert.equal(turnOf({ ...base, life: { ...base.life, stop: 0 } }), "queued");
assert.equal(turnOf({ ...base, worker: { status: "blocked" } }), "orch");
assert.equal(turnOf({ ...base, worker: { status: "working" }, waitsOn: [{ id: "x" }] }), "worker");
assert.equal(turnOf({ ...base, events: eventsOf([c("event=dispatched agent=w-a", 0), c("event=report kind=done", 1, "w-a")]) }), "orch");
assert.equal(turnOf({ ...base, events: eventsOf([c("event=report kind=done", 1, "w-a"), c("event=re-instructed agent=w-a", 2)]) }), "worker");
// A hold that isn't a question for you (remote-closed, a blocked bead) is the orchestrator's, even with a worker at work.
assert.equal(turnOf({ ...base, life: { ...base.life, hold: "remote-closed" }, worker: { status: "working" } }), "orch");
assert.equal(turnOf({ ...base, life: { ...base.life, hold: "blocked", stop: 0 } }), "orch");
const done = { ...base, turn: "done", life: { settled: true, result: "abandoned" } };
assert.equal(turnWord(done), "Abandoned");
assert.equal(turnWord({ ...done, life: { settled: false } }), "Merged, releasing");
assert.equal(turnWord({ turn: "queued" }), "Queued");

// Two review rounds under one reviewer name (the skill reuses r-<stem>): each round is its own row in round order,
// and the closed round 1 never takes the live round-2 terminal by name.
const rr = buildTasks({
  epic: { id: "ep" },
  beads: [{ id: "t", title: "T", status: "in_progress", assignee: "w-t", metadata: { review_round: "2" } }],
  reviews: { t: [
    { id: "r2", title: "Review t round 2", assignee: "r-t", status: "in_progress", created_at: at(30) },
    { id: "r1", title: "Review t round 1", assignee: "r-t", status: "closed", created_at: at(10) },
  ] },
  comments: { t: [c("event=dispatched agent=w-t terminal=t1", 0)], r1: [c("event=dispatched agent=r-t terminal=t2", 10)], r2: [c("event=re-instructed agent=r-t", 30)] },
  terms: [{ address: "t1", name: "w-t", state: "live", status: "idle" }, { address: "t2", name: "r-t", state: "finished" },
    { address: "t3", name: "r-t", state: "live", status: "working" }],
});
assert.deepEqual(rr[0].reviewers.map((r) => [r.bead.id, r.round, r.open, r.worker?.address ?? null, r.worker?.status ?? null]),
  [["r1", 1, false, "t2", "ended"], ["r2", 2, true, "t3", "working"]]);
assert.equal(rr[0].reviewers[1].events[0].name, "re-instructed");
// A same-name worker restart: the newest dispatch's terminal is gone, the live one of that name is the worker.
const restarted = buildTasks({
  epic: { id: "ep" }, beads: [{ id: "t", title: "T", status: "in_progress", assignee: "w-t", metadata: {} }],
  comments: { t: [c("event=dispatched agent=w-t terminal=t1", 0)] },
  terms: [{ address: "t1", name: "w-t", state: "finished" }, { address: "t9", name: "w-t", state: "live", status: "working" }],
});
assert.deepEqual([restarted[0].worker.address, restarted[0].worker.status], ["t9", "working"]);

// summary: what needs you first, then what moves, then progress in done tasks
const sum = summary(tasks);
assert.deepEqual([sum.total, sum.counted, sum.done, sum.merged, sum.you, sum.waiting, sum.working], [5, 5, 0, 0, 1, 1, 1]);
assert.equal(sum.text, "your turn on ABC-16 · 1 working · 0/5 done");
const task = (key, turn, life = {}) => ({ key, turn, life: { merged: false, settled: false, ready: false, pr: null, result: null, ...life } });
const succeeded = (key) => task(key, "done", { merged: true, settled: true, result: "succeeded", pr: "p" });
// The re-instruction's examples: review done and fixes running; a question waiting; a PR ready with nothing running.
assert.equal(summary([succeeded("A-1"), task("A-2", "worker", { pr: "p" })]).text, "1 working · 1/2 done");
const four = [succeeded("ABC-1"), task("ABC-12", "you", { pr: "p" }), task("ABC-13", "orch"), task("ABC-14", "queued")];
assert.deepEqual(summary(four), { total: 4, counted: 4, done: 1, failed: 0, ready: 0, merged: 1, inPr: 1, you: 1, waiting: 0, working: 0,
  text: "your turn on ABC-12 · 1/4 done" });
assert.equal(summary([succeeded("A-1"), task("A-2", "orch", { pr: "p", ready: true }), task("A-3", "queued"), task("A-4", "waiting")]).text,
  "1 PR ready · 1/4 done");
// Every counted task done: "all done"; abandoned work drops out of the total, and failed work isn't done.
assert.equal(summary([succeeded("A-1"), succeeded("A-2")]).text, "all done");
assert.equal(summary([succeeded("A-1"), task("A-2", "done", { settled: true, result: "abandoned" })]).text, "all done");
const failing = summary([succeeded("A-1"), task("A-2", "done", { settled: true, result: "failed" }), task("A-3", "done", { settled: true, result: "uncertain" }),
  task("A-4", "you"), task("A-5", "worker")]);
assert.deepEqual([failing.failed, failing.counted, failing.text], [2, 5, "your turn on A-4 · 2 failed · 1 working · 1/5 done"]);
assert.equal(summary([task("A-1", "you"), task("A-2", "you")]).text, "your turn on 2 tasks · 0/2 done");
// Merged but not settled is not done yet; a bead closed without a settle is.
assert.equal(summary([task("A-1", "done", { merged: true }), task("A-2", "done", { settled: true, result: "closed" })]).text, "1/2 done");
assert.equal(summary([task("A-1", "done", { settled: true, result: "abandoned" })]).text, "", "nothing left to count");
assert.equal(summary([]).text, "");
// "PR ready" needs a PR: a ready event without one isn't counted.
assert.equal(summary([task("A-1", "orch", { ready: true }), task("A-2", "queued")]).text, "0/2 done");
// A reopened task (old abandonment, new dispatch) is back in progress, not dropped from the total.
assert.equal(summary([task("A-1", "worker", { settled: false }), succeeded("A-2")]).text, "1 working · 1/2 done");

// Clock: first sight takes the stale value, then the fetch's; flips come from changes seen later
const asked = [];
let answer;
let redraws = 0;
const clock = new Clock((a) => { asked.push(a); return answer; }, () => redraws++);
answer = Promise.resolve(T0 + 5000);
clock.observe("t1", "idle", T0 - 999, T0 + 9000);
assert.equal(clock.since("t1"), T0 - 999);
assert.equal(clock.flip("t1"), undefined);
await new Promise((r) => setTimeout(r, 5));
assert.equal(clock.since("t1"), T0 + 5000);
assert.equal(redraws, 1);
clock.observe("t1", "idle", 0, T0 + 9500);
assert.deepEqual(asked, ["t1"]);
assert.equal(clock.since("t1"), T0 + 5000);
clock.observe("t1", "working", 0, T0 + 10000);
assert.deepEqual(clock.flip("t1"), { from: "idle", to: "working", at: T0 + 10000 });
assert.equal(clock.since("t1"), T0 + 10000);
clock.observe("t1", "idle", 0, T0 + 20000);
assert.deepEqual(clock.flip("t1"), { from: "working", to: "idle", at: T0 + 20000 });
// a change seen before the fetch answers wins over its answer; a failing or empty fetch keeps the stale value
let late;
const clock2 = new Clock(() => new Promise((r) => { late = r; }));
clock2.observe("t2", "idle", 100, 1000);
clock2.observe("t2", "working", 100, 2000);
await new Promise((r) => setTimeout(r, 5));
late(500);
await new Promise((r) => setTimeout(r, 5));
assert.equal(clock2.since("t2"), 2000);
const clock3 = new Clock(() => Promise.reject(new Error("no hc")));
clock3.observe("t3", "idle", 777, 1000);
await new Promise((r) => setTimeout(r, 5));
assert.equal(clock3.since("t3"), 777);
assert.equal(new Clock(() => null).since("nope"), 0);
// The first sight's fetch starts at once, and takePending hands its promise over (once), so a mod can redraw.
const started = [];
const clock4 = new Clock((a) => { started.push(a); return Promise.resolve(T0 + 1); });
clock4.observe("t4", "idle", 0, T0 + 2);
assert.deepEqual(started, ["t4"], "asked synchronously, not in a later microtask");
const pend = clock4.takePending();
assert.equal(pend.length, 1);
assert.deepEqual(clock4.takePending(), []);
await Promise.all(pend);
assert.equal(clock4.since("t4"), T0 + 1, "applied by the time the pending promise settles");
const clock5 = new Clock(() => { throw new Error("sync throw"); });
clock5.observe("t5", "idle", 42, 1);
await Promise.all(clock5.takePending());
assert.equal(clock5.since("t5"), 42);
clock3.prune([]);
assert.equal(clock3.since("t3"), 0);

// sourceLabel: a session source as a header says it.
assert.equal(sourceLabel("https://linear.app/acme/issue/ABC-12/some-title"), "ABC-12");
assert.equal(sourceLabel("https://linear.app/acme/project/some-project-1a2b3c4d"), "Linear project");
assert.equal(sourceLabel("https://example.atlassian.net/browse/xyz-9"), "XYZ-9");
assert.equal(sourceLabel("https://example.com/plans/next"), "example.com");
assert.equal(sourceLabel("bead-1"), "bead-1");
assert.equal(sourceLabel(""), "");

console.log("agents-shared: ok");
