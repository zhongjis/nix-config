// Beads view helpers (mods/beads/layout.js): graph columns, connectors, session rows, ticket references, keys.
// They import nothing from "herdr", so node loads them. Generic made-up data only.
// Run: node modules/home-manager/services/herdr-app/tests/beads-view.mjs
import assert from "node:assert/strict";
import { buildTasks } from "../mods/shared/tasks.js";
import {
  driftOf, elbow, graphStep, isNewestOpen, isStale, levels, parseKey, pickDefault, place, remoteRef, segments, sessionsOf, shortPath, sourceOf,
} from "../mods/beads/layout.js";

const T0 = Date.parse("2026-01-01T00:00:00Z");
const at = (min) => new Date(T0 + min * 60000).toISOString();
const c = (text, min, author = "o-t9") => ({ text, created_at: at(min), author });
const bead = (id, extra = {}) => ({ id, title: `Task ${id}`, status: "open", labels: [], metadata: {}, ...extra });

// remoteRef: provider, key, Jira base with and without a context path
assert.deepEqual(remoteRef("https://linear.app/example-org/issue/abc-12/some-title"), { provider: "linear", key: "ABC-12", base: null, url: "https://linear.app/example-org/issue/abc-12/some-title" });
assert.equal(remoteRef("https://linear.app/example-org/project/some-project-0a1b").key, null);
assert.equal(remoteRef("https://jira.example.com/browse/ABC-12").base, "https://jira.example.com");
assert.equal(remoteRef("https://example.com/jira/browse/ABC-12?x=1").base, "https://example.com/jira");
assert.equal(remoteRef("https://example.com/jira/browse/ABC-12?x=1").provider, "jira");
assert.equal(remoteRef("https://example.com/other/ABC-12").provider, null);
assert.equal(remoteRef("ABC-12"), null);
assert.equal(remoteRef(undefined), null);

// sourceOf
assert.equal(sourceOf(bead("e", { external_ref: "https://linear.app/example-org/issue/ABC-12/x" })), "ABC-12");
assert.equal(sourceOf(bead("e", { external_ref: "https://linear.app/example-org/project/p-0a1b" })), "Linear project");
assert.equal(sourceOf(bead("e", { metadata: { source: "https://jira.example.com/browse/ABC-9 ABC-10" } })), "ABC-9");
assert.equal(sourceOf(bead("e")), "ad hoc");

// isStale: a session epic with nothing left open (an empty one too) and no live orchestrator; never an ordinary epic
const live = new Set(["t1"]);
const sess = (orch, counts, extra = {}) => ({ epic: bead(`e-${orch}`, { metadata: { session: orch }, ...extra }), orch, counts });
assert.equal(isStale(sess("t2", { total: 3, closed: 3 }), live), true);
assert.equal(isStale(sess("t1", { total: 3, closed: 3 }), live), false);
assert.equal(isStale(sess("t2", { total: 2, closed: 1, open: 1 }), live), false);
assert.equal(isStale(sess("t2", { total: 0 }), live), true);
assert.equal(isStale(sess("t1", { total: 0 }), live), false);
assert.equal(isStale({ epic: bead("plain"), orch: null, counts: { total: 3, closed: 3 } }, live), false);
assert.equal(isStale({ epic: bead("plain"), orch: null, counts: { total: 0 } }, live), false);

// isNewestOpen: the newest created_at of an orchestrator's open epics (the panel shows that one only)
const old = sess("t1", { total: 1 }, { id: "e-old", created_at: at(0) }), fresh = sess("t1", { total: 1 }, { id: "e-new", created_at: at(60) });
const other = sess("t2", { total: 1 }, { id: "e-other", created_at: at(-60) });
assert.equal(isNewestOpen(fresh, [old, fresh, other]), true);
assert.equal(isNewestOpen(old, [old, fresh, other]), false);
assert.equal(isNewestOpen(other, [old, fresh, other]), true);
assert.equal(isNewestOpen({ epic: bead("plain"), orch: null }, [old]), false);

// segments: closed, active, blocked, open
assert.deepEqual(segments({ total: 5, closed: 1, in_progress: 1, blocked: 1, open: 2 }), ["closed", "active", "blocked", "open", "open"]);
assert.deepEqual(segments({ total: 0 }), []);

// A diamond plus a long edge: a -> b, a -> c, b -> d, c -> d, a -> d (skips a column); e alone; a cycle is survived.
const rows = (spec) => {
  const beads = spec.map(([id]) => bead(id));
  const deps = Object.fromEntries(spec.map(([id, ...after]) => [id, after.map((p) => ({ id: p, type: "blocks", status: "open" }))]));
  return buildTasks({ epic: bead("epic"), beads, deps, comments: {}, terms: [] });
};
const dia = rows([["a"], ["b", "a"], ["c", "a"], ["d", "b", "c", "a"], ["e"]]);
const lv = levels(dia);
assert.deepEqual(lv.cols, [["a", "e"], ["b", "c"], ["d"]]);
assert.equal(lv.edges.length, 5);
assert.equal(lv.col.get("d"), 2);
assert.deepEqual(levels(rows([["x", "y"], ["y", "x"]])).cols.flat().sort(), ["x", "y"]);
assert.deepEqual(levels([]).cols, []);
// a prerequisite outside the epic is no edge
assert.equal(levels(rows([["a", "elsewhere"]])).edges.length, 0);

// place: one box per task, columns left to right, no overlap in a column
const sizes = { card: 200, gap: 32, pad: 16, head: 26, rowGap: 14, heightOf: () => 100 };
const g = place(dia, sizes);
assert.equal(g.nodes.get("a").x, 16);
assert.equal(g.nodes.get("b").x, 16 + 232);
assert.equal(g.nodes.get("a").y, 16 + 26);
assert.equal(g.nodes.get("e").y, 16 + 26 + 100 + 14);
assert.equal(g.width, 16 * 2 + 3 * 200 + 2 * 32);
assert.equal(g.height, 16 + 26 + 2 * 100 + 14 + 16);

// graphStep: within a column, then across by nearest height
assert.equal(graphStep(g, "a", "down"), "e");
assert.equal(graphStep(g, "e", "down"), "e");
assert.equal(graphStep(g, "a", "right"), "b");
assert.equal(graphStep(g, "e", "right"), "c");
assert.equal(graphStep(g, "b", "left"), "a");
assert.equal(graphStep(g, "a", "left"), "a");
assert.equal(graphStep(g, "nope", "left"), "nope");

// elbow: flat, down, up, a tight one; pieces never go negative and always end at the target
const covers = (pieces, b) => pieces.some((p) => p.h === 1 && p.y === b.y && p.x + p.w === b.x);
for (const [a, b] of [[{ x: 0, y: 10 }, { x: 100, y: 10 }], [{ x: 0, y: 10 }, { x: 100, y: 90 }], [{ x: 0, y: 90 }, { x: 100, y: 10 }], [{ x: 0, y: 10 }, { x: 100, y: 13 }]]) {
  const pieces = elbow(a, b, 6);
  assert.ok(pieces.length > 0);
  assert.ok(pieces.every((p) => p.w >= 1 && p.h >= 1 && p.x >= a.x && p.x + p.w <= b.x + 1), JSON.stringify(pieces));
  assert.ok(covers(pieces, b), JSON.stringify(pieces));
}
assert.equal(elbow({ x: 0, y: 10 }, { x: 100, y: 10 }).length, 1);
assert.deepEqual(elbow({ x: 0, y: 10 }, { x: 100, y: 90 }, 6).map((p) => p.corner).filter(Boolean), ["tr", "bl"]);
assert.deepEqual(elbow({ x: 0, y: 90 }, { x: 100, y: 10 }, 6).map((p) => p.corner).filter(Boolean), ["br", "tl"]);
assert.deepEqual(elbow({ x: 50, y: 10 }, { x: 40, y: 90 }), []);

// sessionsOf: every w- and r- terminal from dispatch events and review beads, live, hibernated, ended, gone
const events = [
  c("event=dispatched agent=w-abc-12-first terminal=t5 worktree=/home/someone/wt/first kind=work", 1, "o-t9"),
  c("event=dispatched agent=w-abc-12-second terminal=t6 worktree=/home/someone/wt/second kind=work", 30, "o-t9"),
  c("event=dispatched agent=o-helper terminal=t2", 31),
];
const task = buildTasks({
  epic: bead("epic"),
  beads: [bead("t1", { assignee: "w-abc-12-second", metadata: { review_round: "1" } })],
  comments: { t1: events, rb: [c("event=dispatched agent=r-abc-12 terminal=t8", 40)] },
  reviews: { t1: [bead("rb", { title: "Review ABC-12", assignee: "r-abc-12" })] },
  terms: [
    { address: "t6", name: "w-abc-12-second", state: "live", status: "working", labels: {} },
    { address: "t5", name: "w-abc-12-first", state: "exited", exit_code: 0, cwd: "/home/someone/wt/first", parent: "t9", labels: { resume: "env BEADS_ACTOR=w-abc-12-first pi --session x1", space: "s1" } },
  ],
  hibernated: [],
})[0];
const ss = sessionsOf(task, { terms: [
  { address: "t6", name: "w-abc-12-second", state: "live", status: "working", labels: {} },
  { address: "t5", name: "w-abc-12-first", state: "exited", exit_code: 0, cwd: "/home/someone/wt/first", parent: "t9", labels: { resume: "env BEADS_ACTOR=w-abc-12-first pi --session x1", space: "s1" } },
  { address: "t3", name: "r-abc-12", state: "live", status: "idle", labels: {} },
], listed: new Map([["t6", "blocked"]]), hibernated: [] });
assert.deepEqual(ss.map((s) => [s.name, s.role, s.state]), [["w-abc-12-first", "worker", "ended"], ["w-abc-12-second", "worker", "blocked"], ["r-abc-12", "reviewer", "idle"]]);
assert.equal(ss[0].resume, "env BEADS_ACTOR=w-abc-12-first pi --session x1");
assert.equal(ss[2].round, 1);
assert.ok(ss.every((s) => !("revive" in s)));
// hibernated and gone
const sleeping = sessionsOf(task, { terms: [], hibernated: [{ address: "t5", name: "w-abc-12-first", line: "pi --session x1", cwd: "/x" }] });
assert.equal(sleeping[0].state, "hibernated");
assert.equal(sleeping[0].resume, "pi --session x1");
assert.equal(sleeping[1].state, "gone");

// A worker restarted under the same name keeps one row, at its newest address
const ev = (name, agent, terminal) => ({ name, at: 0, fields: { agent, terminal } });
const restarted = sessionsOf({
  events: [ev("dispatched", "w-abc-12-first", "t5"), ev("handed-off", "w-abc-12-first", "t9")],
  worker: null, reviewers: [],
}, { terms: [{ address: "t5", state: "exited", exit_code: 0 }, { address: "t9", name: "w-abc-12-first", state: "live", status: "working" }] });
assert.deepEqual(restarted.map((s) => [s.name, s.address, s.state]), [["w-abc-12-first", "t9", "working"]]);
const gone = sessionsOf({ events: [ev("dispatched", "w-abc-12-first", "t5"), ev("dispatched", "w-abc-12-first", "t9")], worker: null, reviewers: [] }, { terms: [] });
assert.deepEqual(gone.map((s) => [s.name, s.address, s.state]), [["w-abc-12-first", "t9", "gone"]]);

// One reviewer name reused across review rounds: one row per round. The closed round 1 keeps its own (finished)
// terminal; only the open round 2 may take the live terminal by name.
const reused = sessionsOf({
  events: [], worker: null,
  reviewers: [
    { bead: bead("rb1", { assignee: "r-abc-12", status: "closed" }), round: 1, open: false, worker: null,
      events: [{ name: "dispatched", fields: { agent: "r-abc-12", terminal: "t1" } }] },
    { bead: bead("rb2", { assignee: "r-abc-12" }), round: 2, open: true, worker: null, events: [] },
  ],
}, { terms: [{ address: "t1", name: "r-abc-12", state: "finished" }, { address: "t3", name: "r-abc-12", state: "live", status: "idle" }] });
assert.deepEqual(reused.map((s) => [s.name, s.role, s.round, s.address, s.state]),
  [["r-abc-12", "reviewer", 1, "t1", "ended"], ["r-abc-12", "reviewer", 2, "t3", "idle"]]);
// A closed round whose terminal is gone stays gone, not the later live one.
const goneRound = sessionsOf({ events: [], worker: null, reviewers: [
  { bead: bead("rb1", { assignee: "r-abc-12", status: "closed" }), round: 1, open: false, worker: null, events: [] }] },
{ terms: [{ address: "t3", name: "r-abc-12", state: "live", status: "working" }] });
assert.deepEqual(goneRound.map((s) => [s.round, s.address, s.state]), [[1, null, "gone"]]);

// driftOf: the newest remote body note
const evs = [
  { name: "note", at: 1, fields: { detail: "remote body changed before dispatch" } },
  { name: "note", at: 2, fields: { detail: "something else" } },
  { name: "note", at: 3, fields: { detail: "remote body changed after the pull" } },
];
assert.deepEqual(driftOf(evs), { at: 3, text: "remote body changed after the pull" });
assert.equal(driftOf([]), null);

// pickDefault: yours, then a worker's, then the first open one
assert.equal(pickDefault([{ id: "a", turn: "done" }, { id: "b", turn: "worker" }, { id: "c", turn: "you" }]), "c");
assert.equal(pickDefault([{ id: "a", turn: "done" }, { id: "b", turn: "queued" }]), "b");
assert.equal(pickDefault([{ id: "a", turn: "done" }]), "a");
assert.equal(pickDefault([]), null);

// parseKey: ours are plain keys; chords belong to someone else
const key = (k, modifiers = {}) => ({ key: k, modifiers });
assert.equal(parseKey(key("down")), "down");
assert.equal(parseKey(key("tab")), "tab");
assert.equal(parseKey(key("tab", { shift: true })), "shift-tab");
assert.equal(parseKey(key("enter")), "enter");
assert.equal(parseKey(key("escape")), "escape");
assert.equal(parseKey(key("down", { control: true })), null);
assert.equal(parseKey(key("a")), null);

// shortPath
assert.equal(shortPath("/home/someone/wt/x", "/home/someone"), "~/wt/x");
assert.equal(shortPath("/home/someone2/x", "/home/someone"), "/home/someone2/x");
assert.equal(shortPath("/x", ""), "/x");

console.log("beads-view: ok");
