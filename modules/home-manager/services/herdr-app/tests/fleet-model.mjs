// fleet mod checks: the fleet derivation (tree, status, supervising, urgency order, default open root, beads
// meeting their workers) on a small made-up fleet. Exits nonzero on a failure.
// Run: node modules/home-manager/services/herdr-app/tests/fleet-model.mjs
import assert from "node:assert/strict";
import { parseEvent, lifecycle, buildFleet, eventsOf } from "../mods/fleet/model.js";
import { fixtureEpics } from "../mods/fleet/fixtures.js";

const ev = parseEvent({ text: "event=dispatched agent=w-a terminal=t9\n\nbody", created_at: "2026-01-01T00:00:00Z" });
assert.deepEqual([ev?.name, ev?.fields, ev?.body], ["dispatched", { agent: "w-a", terminal: "t9" }, "body"]);
assert.equal(parseEvent({ text: "just a note" }), null);

const review = lifecycle({ id: "b1", metadata: { pr_url: "x/pull/1", review_round: "2" } }, []);
assert.deepEqual([review.step, review.round, review.pr], [3, 2, "x/pull/1"]);
assert.equal(lifecycle({ id: "b2", metadata: { blocked_reason: "needs-user" } }, eventsOf([{ text: "event=dispatched agent=w-b" }])).blocked, "needs-user");
assert.equal(lifecycle({ id: "b3", metadata: {} }, eventsOf([{ text: "event=settled result=succeeded" }])).step, 5);

const now = Date.parse("2026-01-01T12:00:00Z");
/** @param {string} address @param {string} status @param {string} [tab] */
const agent = (address, status, tab = "1") => ({ address, status, space_name: "repo", tab_name: tab, title: address, app: "pi" });
const agents = [agent("o1", "idle", "[o] ship it"), agent("a2", "idle"), agent("a3", "working"), agent("a4", "blocked")];
const terminals = [
  { address: "o1", state: "live", status: "idle" },
  { address: "a2", state: "live", status: "idle" },
  { address: "a3", state: "live", status: "working" },
  { address: "a4", state: "live", status: "blocked" },
  { address: "w1", name: "w-thing", parent: "o1", state: "live", status: "working", labels: { orch: "o1" }, report: { msg: "on it" } },
  { address: "w2", name: "w-other", parent: "o1", state: "live", status: "done", labels: { orch: "o1" } },
  { address: "x1", name: "ocr", parent: "a2", state: "finished", exit_code: 2 },
  { address: "r9", name: "r-orphan", parent: "t40", state: "live", status: "done", labels: { orch: "t40", where: "repo / [o] old" } },
];
// o1's epic: one task dispatched to w1's terminal, one assigned to w-other by name, one whose worker is gone.
const live = [{ epic: { id: "e1" }, tasks: [
  { bead: { id: "e1.1", title: "Do the thing", status: "in_progress" }, events: eventsOf([{ text: "event=dispatched agent=w-thing terminal=w1" }]) },
  { bead: { id: "e1.2", title: "Do the other", status: "in_progress", assignee: "w-other" }, events: [] },
  { bead: { id: "e1.3", title: "Gone", status: "closed", assignee: "w-gone" }, events: eventsOf([{ text: "event=settled result=succeeded" }]) },
] }];
const fleet = buildFleet({ agents, terminals, beads: { mode: "live", byOrch: new Map([["o1", live]]) } });
const byId = new Map(fleet.roots.map((r) => [r.node.id, r]));

// Urgency: needs you, failed, working (o1 supervises, a3 works), done (the ended stand-in's finished worker).
assert.deepEqual(fleet.roots.map((r) => [r.node.id, r.tier]),
  [["a4", "needs"], ["a2", "failed"], ["o1", "working"], ["a3", "working"], ["t40", "done"]]);
// Default open: the most urgent root with children (a4 has none).
assert.equal(fleet.defaultOpen, "a2");

// o1 rests while w1 works: it supervises, and its rollup counts the work and its tasks.
const o1 = byId.get("o1");
assert.deepEqual([o1?.node.status, o1?.node.shown, o1?.orch], ["idle", "supervising", true]);
assert.equal(o1?.rollup.text, "1 working · 1/3 tasks done");
// Beads meet workers by dispatched terminal (w1) and by assignee (w2); the third stays a bead card.
const [w1, w2, gone] = o1?.node.children ?? [];
assert.deepEqual([w1.bead?.id, w1.task, w1.life?.step, w1.report], ["e1.1", "Do the thing", 1, "on it"]);
assert.deepEqual([w2.bead?.id, w2.task, w2.life?.step], ["e1.2", "Do the other", 0]);
assert.deepEqual([gone.kind, gone.name, gone.status], ["bead", "w-gone", "done"]);

// The ended parent's worker stays visible under a stand-in that sums up its children.
const ended = byId.get("t40");
assert.deepEqual([ended?.node.kind, ended?.node.shown, ended?.rollup.text, ended?.rollup.unbeaded], ["ended", "idle", "1 done", 1]);
// A tool child that exited nonzero failed; it never inherits a title as its task.
assert.deepEqual([byId.get("a2")?.node.children[0].status, byId.get("a2")?.node.children[0].task], ["failed", ""]);
// Idle with nothing working under it stays idle.
assert.equal(byId.get("a2")?.node.shown, "idle");
assert.deepEqual(fleet.summary, { agents: 5, subAgents: 4, working: 2, needs: 1, failed: 1, epics: 1, finished: 1, tasks: 3 });
assert.deepEqual(fleet.order, ["a4", "a2", "o1", "w1", "w2", "a3", "r9"]);

// Fixture beads land on the first orchestrator; with none, on a stand-in one.
const fx = buildFleet({ agents, terminals, beads: { mode: "fixture", epics: fixtureEpics(now) } });
const fxHost = fx.roots.find((r) => r.node.id === "o1");
assert.deepEqual(fxHost?.node.children.filter((n) => n.kind === "bead").map((n) => [n.status, n.life?.step]),
  [["done", 4], ["idle", 3], ["blocked", 1], ["queued", 0]]);
const lone = buildFleet({ agents: [agents[1]], terminals: terminals.slice(1, 2), beads: { mode: "fixture", epics: fixtureEpics(now) } });
assert.ok(lone.roots.some((r) => r.node.kind === "synthetic"));

console.log("fleet-model: ok");
