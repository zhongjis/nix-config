// fleet mod checks: the Agents panel's model (roots and trees, task order and turns on the sample session, the
// timeline, pulses, answer routing, PR matching) on made-up data. No herdr import. Exits nonzero on a failure.
// Run: node modules/home-manager/services/herdr-app/tests/fleet-model.mjs
import assert from "node:assert/strict";
import {
  buildRoots, descendants, isSolo, orderTasks, sessionView, slotsOf, prNumber, prFor, eventLabel, newestLine, timelineOf,
  rowPasses, orchIn, pulsesOf, answerState, answerMessage, reachOf, LONG_HOLD, PULSE_WINDOW,
} from "../mods/fleet/model.js";
import { fixtureSession, fixtureTerms, fixtureHibernated } from "../mods/fleet/fixtures.js";
import { eventsOf } from "../mods/fleet/events.js";

// ----- roots and trees -------------------------------------------------------------------------------------------
const agent = (address, status, tab = "1", extra = {}) => ({ address, status, space_name: "repo", tab_name: tab, title: address, ...extra });
const agents = [agent("o1", "idle", "[o] ship it"), agent("a2", "idle"), agent("a3", "working"), agent("a4", "blocked")];
const terminals = [
  { address: "o1", state: "live", status: "idle" },
  { address: "a2", state: "live", status: "idle" },
  { address: "a3", state: "live", status: "working" },
  { address: "a4", state: "live", status: "blocked" },
  { address: "w1", name: "w-abc-12-keys", parent: "o1", state: "live", status: "working", labels: { orch: "o1" }, report: { msg: "on it" } },
  { address: "w2", name: "w-abc-13-docs", parent: "o1", state: "live", status: "done", labels: { orch: "o1" } },
  { address: "x1", name: "ocr", parent: "a2", state: "finished", exit_code: 2 },
  { address: "x2", name: "tail", parent: "a3", state: "live" },
  { address: "r9", name: "r-orphan", parent: "t40", state: "live", status: "done", labels: { orch: "t40" } },
];
const nameOf = (k) => k.name ?? k.title ?? k.address;
const roots = buildRoots({ agents, terminals, nameOf });
const byAddress = new Map(roots.map((r) => [r.address, r]));

assert.deepEqual(roots.map((r) => r.address), ["o1", "a2", "a3", "a4", "t40"]);
// An orchestrator: the tab mark, or workers labelled with its address; the ended parent's stand-in too.
assert.deepEqual(roots.map((r) => r.orch), [true, false, false, false, true]);
// It rests (idle) while a worker works: its tree reads Working; its own word stays.
const o1 = byAddress.get("o1").node;
assert.deepEqual([o1.status, o1.shown, o1.children.map((c) => c.name)], ["idle", "working", ["w-abc-12-keys", "w-abc-13-docs"]]);
assert.equal(o1.children[0].report, "on it");
// A tool that works runs; a finished child that failed shows, as failed; a clean exit is old news.
assert.deepEqual(byAddress.get("a3").node.children.map((c) => [c.kind, c.status]), [["tool", "running"]]);
assert.deepEqual(byAddress.get("a2").node.children.map((c) => [c.name, c.status, c.live]), [["ocr", "failed", false]]);
// The ended parent's worker stays visible under a stand-in.
const ended = byAddress.get("t40").node;
assert.deepEqual([ended.kind, ended.status, ended.children.map((c) => c.address)], ["ended", "ended", ["r9"]]);
assert.deepEqual(descendants(o1).map((n) => n.address), ["w1", "w2"]);
// Solo: no children and (no epic or not an orchestrator).
assert.deepEqual([isSolo(byAddress.get("a4"), false), isSolo(byAddress.get("a2"), false), isSolo(byAddress.get("o1"), true)], [true, false, false]);
assert.equal(isSolo({ node: { children: [] }, orch: true }, false), true);
assert.equal(isSolo({ node: { children: [] }, orch: true }, true), false);
// A root's own done stays done (as the rail says it); only a sub-agent's done reads idle.
const doneRoot = buildRoots({ agents: [agent("d1", "done")], terminals: [{ address: "d1", state: "live", status: "done" },
  { address: "dk", parent: "d1", state: "live", status: "done", name: "w-d" }], nameOf });
assert.deepEqual([doneRoot[0].node.status, doneRoot[0].node.children[0].status], ["done", "idle"]);
// A live worker whose finished parent is still listed shows under the parent's stand-in, not nowhere.
const outlived = buildRoots({ agents: [], nameOf, terminals: [{ address: "op", state: "finished", name: "[o] gone" },
  { address: "ow", parent: "op", state: "live", status: "working", name: "w-x", labels: { orch: "op" } }] });
assert.deepEqual(outlived.map((r) => [r.address, r.orch, r.node.children.map((c) => c.address)]), [["op", true, ["ow"]]]);
// A live parent that isn't drawn (a plain shell) makes no stand-in.
assert.deepEqual(buildRoots({ agents: [], nameOf, terminals: [{ address: "sh", state: "live" },
  { address: "kid", parent: "sh", state: "live", status: "working", labels: { orch: "sh" } }] }), []);

// ----- the sample session ----------------------------------------------------------------------------------------
const now = Date.now();
const terms = fixtureTerms();
const view = sessionView({ session: fixtureSession(now), terms, listed: new Map(), hibernated: fixtureHibernated(now), now });
const row = new Map(view.tasks.map((t) => [t.key, t]));
assert.deepEqual([view.source, view.mode.flags, view.mode.max], ["ABC-10", "--auto", 2]);
// Dependency order (ABC-12 before ABC-14), settled last.
assert.deepEqual(view.tasks.map((t) => t.key), ["ABC-12", "ABC-13", "ABC-14", "ABC-15", "ABC-16", "ABC-11"]);
assert.deepEqual(view.tasks.map((t) => t.turn), ["worker", "you", "waiting", "slot", "worker", "done"]);
assert.equal(view.summary.text, "your turn on ABC-13 · 2 working · 1/6 done");
// Review rounds sit in their task; the reviewer is no worker without a bead.
assert.deepEqual(row.get("ABC-12").reviewers.map((r) => [r.round, r.bead.status, r.worker?.name]), [[1, "closed", "r-abc-12-events"]]);
assert.equal(row.get("ABC-14").waitsOn[0].key, "ABC-12");
assert.deepEqual(row.get("ABC-12").blocks.map((b) => b.key), ["ABC-14"]);
assert.equal(row.get("ABC-16").worker.status, "hibernated");
assert.equal(row.get("ABC-13").life.holdQuestion, "Keep closed beads 30 or 90 days? 90 doubles the database size.\nThe 30 day option drops old review rounds first.");
assert.equal(newestLine(row.get("ABC-12"), now), "Pushed 02e0d60 · 9m · Merging it readies ABC-14");
assert.equal(newestLine(row.get("ABC-11"), now), "Settled · 8h");
// The order keeps a cycle's tasks rather than dropping them.
const cyc = [{ id: "a", turn: "worker", blocks: [{ id: "b" }] }, { id: "b", turn: "worker", blocks: [{ id: "a" }] }];
assert.deepEqual(orderTasks(cyc).map((t) => t.id), ["a", "b"]);

// Slots, as slot-free.sh counts them: this orchestrator's live w-/r- terminals whose own status is working.
assert.equal(slotsOf(terminals, "o1"), 1);
assert.equal(slotsOf([...terminals, { address: "q1", name: "helper", parent: "o1", state: "live", status: "working", labels: { orch: "o1" } }], "o1"), 1,
  "a labelled terminal that is no w-/r- agent holds no slot");
assert.equal(slotsOf([...terminals, { address: "r2", name: "r-abc-12-rev", state: "live", status: { state: "working" }, labels: { orch: "o1" } }], "o1"), 2);
assert.equal(slotsOf(terminals, "t99"), 0);

// ----- the timeline ----------------------------------------------------------------------------------------------
const tl = timelineOf(row.get("ABC-12").events, now);
assert.deepEqual(tl.groups.map((g) => [g.n, g.rows.length]), [[1, 2], [2, 2], [3, 3]]);
assert.equal(tl.count, 7);
assert.equal(tl.roundCount, 3);
// Oldest first; each row keyed by time and index.
const rows = tl.groups.flatMap((g) => g.rows);
assert.deepEqual(rows.map((r) => r.i), [0, 1, 2, 3, 4, 5, 6]);
assert.ok(rows.every((r, i) => i === 0 || r.event.at >= rows[i - 1].event.at));
assert.match(rows[0].key, /^\d+:0$/);
// A decision keeps its whole question and answer; whose it is shows in its label.
const decided = rows.find((r) => r.event.name === "decided");
assert.deepEqual([decided.event.fields.q, decided.event.fields.a, decided.label],
  ["Squash or keep the three commits?", "Squash: the history is noise.", "Orchestrator decided"]);
assert.equal(eventLabel(eventsOf([{ text: "event=decided by=user q=x a=y" }])[0]), "You decided");
// The question to you: the asker is the orchestrator, the avatar and the hold are yours; the wait is long.
const ask = timelineOf(row.get("ABC-13").events, now);
const asked = ask.groups.flatMap((g) => g.rows).at(-1);
assert.deepEqual([asked.label, asked.kind, asked.holder, asked.note], ["Asked you", "you", "you", "waiting on you"]);
assert.ok(asked.ms > LONG_HOLD);
assert.ok(ask.totals.you > 2 * 3600000 && ask.totals.you > ask.totals.orch);
assert.equal(ask.totals.worker + ask.totals.orch + ask.totals.you, ask.groups.flatMap((g) => g.rows).reduce((s, r) => s + r.ms, 0));
// Filters.
assert.deepEqual(rows.filter((r) => rowPasses(r, "decisions")).map((r) => r.event.name), ["decided"]);
assert.ok(rows.filter((r) => rowPasses(r, "reports")).every((r) => r.event.name === "report"));
assert.deepEqual(rows.filter((r) => rowPasses(r, "instructions")).map((r) => r.event.name), ["dispatched", "re-instructed", "dispatched"]);
assert.equal(rows.filter((r) => rowPasses(r, "all")).length, 7);
// Events before the first dispatch form round 0; the empty task has no rounds.
assert.equal(timelineOf(eventsOf([{ text: "event=note detail=hello", created_at: "2026-01-01T00:00:00Z" }]), Date.parse("2026-01-01T01:00:00Z")).groups[0].n, 0);
assert.deepEqual(timelineOf([], now).groups, []);

// ----- pulses ----------------------------------------------------------------------------------------------------
const worker = { address: "w1" };
const task = { turn: "worker", worker };
assert.deepEqual(orchIn("1795600000000:re-instructed"), { at: 1795600000000, kind: "re-instructed" });
assert.equal(orchIn("soon"), null);
const keys = (p) => p.map((x) => [x.down, x.tone, x.kind]);
assert.deepEqual(keys(pulsesOf({ task, flip: { from: "idle", to: "working", at: now - 1000 }, now })), [[true, "accent", ""]]);
assert.deepEqual(keys(pulsesOf({ task, flip: { from: "working", to: "idle", at: now - 1000 }, now })), [[false, "done", ""]]);
assert.deepEqual(keys(pulsesOf({ task, flip: { from: "working", to: "blocked", at: now - 1000 }, now })), [[false, "blocked", ""]]);
assert.deepEqual(pulsesOf({ task, flip: { from: "idle", to: "working", at: now - PULSE_WINDOW - 1 }, now }), []);
assert.deepEqual(pulsesOf({ task, flip: { from: "idle", to: "done", at: now - 1000 }, now }), []);
assert.deepEqual(keys(pulsesOf({ task, label: `${now - 2000}:command`, now })), [[true, "accent", "command"]]);
assert.deepEqual(pulsesOf({ task, label: `${now - 9000}:command`, now }), []);
assert.deepEqual(pulsesOf({ task: { turn: "done", worker }, flip: { from: "idle", to: "working", at: now }, now }), []);
assert.deepEqual(pulsesOf({ task: { turn: "queued", worker: null }, label: `${now}:x`, now }), []);

// ----- answers and PRs -------------------------------------------------------------------------------------------
const orchOk = { live: true, status: "idle" };
assert.equal(answerState({ turn: "you" }, orchOk), "answer");
assert.equal(answerState({ turn: "you" }, { live: true, status: "blocked" }), "orch-blocked");
assert.equal(answerState({ turn: "you" }, { live: false, status: "ended" }), "no-orch");
assert.equal(answerState({ turn: "you" }, null), "no-orch");
assert.equal(answerState({ turn: "orch", worker: { status: "blocked" } }, orchOk), "worker-prompt");
assert.equal(answerState({ turn: "worker", worker: { status: "working" } }, orchOk), null);
assert.equal(answerMessage({ key: "ABC-13", id: "fx-1.3", qid: "c-9", question: "Keep 30 or 90 days?\nIt doubles the size.", text: "90" }),
  "Answer from the herdr-app panel for ABC-13 (bead fx-1.3, question c-9). Question: Keep 30 or 90 days? It doubles the size.. Answer: 90");
// The sample's question carries its comment id, so a panel answer can name it.
assert.ok(row.get("ABC-13").life.holdQuestionId);

// ----- session rows: Peek for a hidden agent, Focus for one on another tab, nothing for one on screen -------------
const panes = [{ pane: "p1", terminal: "t-here", tab: "tab-1" }, { pane: "p2", terminal: "t-away", tab: "tab-2" }];
assert.equal(reachOf("t-hidden", panes, "tab-1"), "peek", "no pane: a hidden worker or reviewer");
assert.equal(reachOf("t-here", panes, "tab-1"), null, "its pane is on the current tab");
assert.equal(reachOf("t-away", panes, "tab-1"), "focus", "its pane is on another tab or space");
assert.equal(reachOf("t-away", [], "tab-1"), "peek");

assert.deepEqual([prNumber("https://github.com/acme/skills/pull/412"), prNumber("#12"), prNumber("604"), prNumber(""), prNumber(null)], ["412", "12", "604", null, null]);
const prs = { "acme/skills": [{ number: 412, url: "https://github.com/acme/skills/pull/412", ci: "pass" }], "acme/web": [{ number: 412, url: "https://github.com/acme/web/pull/412" }, { number: 7, url: "https://github.com/acme/web/pull/7" }] };
assert.equal(prFor(prs, "https://github.com/acme/skills/pull/412").repo, "acme/skills");
assert.equal(prFor(prs, "https://github.com/acme/web/pull/412").repo, "acme/web");
assert.equal(prFor(prs, "7").repo, "acme/web");
assert.equal(prFor(prs, "412"), null, "a bare number two repos share names none");
assert.equal(prFor(prs, "https://github.com/other/repo/pull/9"), null);
// A URL never matches another repo's PR with the same number; the same repo with a different URL form still does.
assert.equal(prFor({ "acme/web": [{ number: 7, url: "https://github.com/acme/web/pull/7" }] }, "https://github.com/acme/skills/pull/7"), null);
assert.equal(prFor({ "acme/web": [{ number: 7, url: "https://github.com/acme/web/pull/7" }] }, "https://github.com/Acme/Web/pull/7/").repo, "acme/web");
// Another forge with the same owner/name and number is another PR.
assert.equal(prFor({ "acme/web": [{ number: 7, url: "https://forge-a.example/acme/web/pull/7" }] }, "https://forge-b.example/acme/web/pull/7"), null);
assert.equal(prFor({ "forge-a.example/acme/web": [{ number: 7 }] }, "https://forge-a.example/acme/web/pull/7").repo, "forge-a.example/acme/web");
assert.equal(prFor({ "acme/web": [{ number: 7 }] }, "https://forge-b.example/acme/web/pull/7"), null, "a key without a host is github.com's");
// A replacement PR: the task's newest PR is what's matched, not the old one in the feed.
assert.equal(prFor(prs, "https://github.com/acme/web/pull/8"), null);
assert.equal(prFor(undefined, "7"), null);

console.log("fleet-model: ok");
