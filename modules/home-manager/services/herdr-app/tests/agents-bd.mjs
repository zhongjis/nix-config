// The shared bd.js loaders against a fake `bd` (exec is stubbed; no database is touched): an orchestrator's session is
// its newest open epic, the rail's summary read and the panel's full read give the same task rows for closed, idle and
// hibernated tasks, a read costs one batched `bd show`, and liveHold reads the bead's current question. Made-up data.
// Run: node modules/home-manager/services/herdr-app/tests/agents-bd.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { buildTasks, summary } from "../mods/shared/tasks.js";

// bd.js imports exec and hc from "herdr": load it with those taken from globalThis, its own imports made absolute.
const shared = new URL("../mods/shared/", import.meta.url);
const src = readFileSync(new URL("bd.js", shared), "utf8")
  .replace('import { exec, hc } from "herdr";', "const { exec, hc } = globalThis.__herdr;")
  .replace(/from "\.\/([^"]+)"/g, (_m, f) => `from "${new URL(f, shared).href}"`);
const calls = [];
let db;
// bd.js keeps the functions it imported, so the stub forwards to `answer`, which a check may swap.
let answer = (argv) => {
  const out = bd(argv);
  return out === undefined ? { code: 1, stdout: "", stderr: `unknown: ${argv.join(" ")}` } : { code: 0, stdout: JSON.stringify(out), stderr: "" };
};
globalThis.__herdr = {
  hc: async () => ({ code: 1, stdout: "", stderr: "" }),
  exec: async (cmd, args) => {
    const argv = cmd === "/usr/bin/env" ? args.slice(2) : args;
    calls.push(argv);
    return answer(argv);
  },
};
const bdjs = await import(`data:text/javascript;base64,${Buffer.from(src).toString("base64")}`);
const { loadSession, loadSummaries, liveHold, newestEpic, bdConfig } = bdjs;

const at = (min) => new Date(Date.parse("2026-01-01T00:00:00Z") + min * 60000).toISOString();
const comment = (id, text, min, author = "o-O") => ({ id, text, created_at: at(min), author });

// The fake database: O has two open epics (e-new is newest); its tasks are closed without a settle, idle after a
// report, and hibernated after a report.
function fakeDb() {
  const epics = [
    { id: "e-old", title: "old", issue_type: "epic", status: "open", created_at: at(0), metadata: { session: "O" } },
    { id: "e-new", title: "new", issue_type: "epic", status: "open", created_at: at(100), metadata: { session: "O" } },
    { id: "e-other", title: "other", issue_type: "epic", status: "open", created_at: at(200), metadata: { session: "P" } },
  ];
  const tasks = {
    "e-new": [
      { id: "b1", title: "One", status: "closed", assignee: "w-one", metadata: {} },
      { id: "b2", title: "Two", status: "in_progress", assignee: "w-two", metadata: JSON.stringify({ pr_url: "https://example.test/o/r/pull/2" }) },
      { id: "b3", title: "Three", status: "in_progress", assignee: "w-three", metadata: { review_round: "1" } },
      { id: "b4", title: "Four", status: "in_progress", assignee: "w-four", metadata: { blocked_reason: "needs-user" } },
    ],
    "e-old": [{ id: "x1", title: "Old", status: "open", metadata: {} }],
    b3: [{ id: "rv1", title: "Review b3 round 1", assignee: "r-three", status: "in_progress", metadata: {} }],
  };
  const comments = {
    "e-new": [comment("m1", "event=mode flags=--auto max=2", 100)],
    b1: [comment("c1", "event=dispatched agent=w-one terminal=W1", 101)],
    b2: [comment("c2", "event=dispatched agent=w-two terminal=W2", 101), comment("c3", "event=report kind=pr-opened pr=https://example.test/o/r/pull/2", 110, "w-two")],
    b3: [comment("c4", "event=dispatched agent=w-three terminal=W3", 101), comment("c5", "event=report kind=ready-local", 120, "w-three")],
    b4: [comment("c6", "event=dispatched agent=w-four terminal=W4", 101), comment("c7", "event=blocked reason=needs-user\n\nOld question?", 130),
      comment("c8", 'event=blocked reason=needs-user q="Keep 30 or 90 days?\\nIt doubles the size."', 140)],
    rv1: [comment("c9", "event=dispatched agent=r-three terminal=R3", 121)],
  };
  const deps = { b2: [{ id: "b1", dependency_type: "blocks", status: "closed" }, { id: "e-new", dependency_type: "parent-child" }] };
  return { epics, tasks, comments, deps, config: { "jira.url": "https://tracker.example" } };
}
const all = () => [...db.epics, ...Object.values(db.tasks).flat()];
function bd(argv) {
  const [cmd, ...rest] = argv;
  const opt = (name) => { const i = rest.indexOf(name); return i >= 0 ? rest[i + 1] : undefined; };
  assert.equal(argv.at(-1), "--json");
  if (cmd === "list" && opt("--type") === "epic") {
    const field = opt("--metadata-field");
    return db.epics.filter((e) => !field || `session=${e.metadata.session}` === field);
  }
  if (cmd === "list" && opt("--parent")) return db.tasks[opt("--parent")] ?? [];
  if (cmd === "show") {
    const ids = rest.filter((x) => !x.startsWith("--"));
    return ids.map((id) => ({ ...all().find((b) => b.id === id), dependencies: db.deps[id] ?? [],
      ...(rest.includes("--include-comments") ? { comments: db.comments[id] ?? [] } : {}) }));
  }
  if (cmd === "config" && rest[0] === "get") return { key: rest[1], value: db.config[rest[1]] ?? "" };
  return undefined;
}

db = fakeDb();
// The session is the newest open epic; older ones are only counted.
calls.length = 0;
const { session, extra } = await loadSession("O", "/beads");
assert.deepEqual([session.epic.id, extra], ["e-new", 1]);
assert.deepEqual(session.mode, { flags: "--auto", max: 2, at: Date.parse(at(100)) });
assert.deepEqual(session.beads.map((b) => b.id), ["b1", "b2", "b3", "b4"]);
assert.equal(session.beads[1].metadata.pr_url, "https://example.test/o/r/pull/2", "metadata given as a JSON string reads as an object");
assert.deepEqual(session.deps.b2, [{ id: "b1", type: "blocks", status: "closed" }]);
assert.deepEqual(session.reviews.b3.map((r) => r.id), ["rv1"]);
assert.equal(session.comments.b4[2].id, "c8", "comments keep their ids");
// Cost: the epic list, the children, one list per task under review, one batched show (deps and comments together).
assert.deepEqual(calls.map((c) => c.slice(0, 2).join(" ")), ["list --type", "list --parent", "list --parent", "show e-new"]);
assert.ok(calls.at(-1).includes("--include-comments") && calls.at(-1).includes("rv1"));

// The rail's read and the panel's read agree, through the same rows.
const ctx = {
  terms: [
    { address: "O", state: "live", status: "working" },
    { address: "W2", name: "w-two", parent: "O", state: "live", status: "idle", labels: { orch: "O" } },
    { address: "W4", name: "w-four", parent: "O", state: "live", status: "idle", labels: { orch: "O" } },
    { address: "R3", name: "r-three", parent: "O", state: "live", status: "working", labels: { orch: "O" } },
  ],
  listed: new Map(), hibernated: [{ address: "W3", name: "w-three", parent: "O" }], now: Date.parse(at(200)),
};
calls.length = 0;
const found = await loadSummaries(["O", "P", "Q"], "/beads");
assert.equal(calls.filter((c) => c[0] === "list" && c.includes("epic")).length, 1, "one epic list for every orchestrator");
assert.deepEqual([...found.keys()].sort(), ["O", "P", "Q"]);
assert.equal(found.get("Q").session, null);
assert.equal(found.get("P").session.epic.id, "e-other");
const rail = buildTasks({ ...found.get("O").session, ...ctx });
const panel = buildTasks({ ...session, ...ctx });
const facts = (rows) => rows.map((t) => [t.key, t.turn, t.life.settled, t.life.result, t.worker?.status ?? null]);
assert.deepEqual(facts(rail), facts(panel));
assert.deepEqual(facts(panel), [
  ["b1", "done", true, "closed", null], // closed without a settle: settled, not queued
  ["b2", "orch", false, null, "idle"], // idle after its report: the orchestrator's turn, not working
  ["b3", "orch", false, null, "hibernated"], // hibernated after its report: the orchestrator's turn, not working
  ["b4", "you", false, null, "idle"],
]);
assert.deepEqual(summary(rail), summary(panel));
assert.equal(summary(rail).working, 0, "nothing reads working when no worker works");
assert.equal(panel.find((t) => t.id === "b4").life.holdQuestionId, "c8");
assert.equal(panel.find((t) => t.id === "b4").life.holdQuestion, "Keep 30 or 90 days?\nIt doubles the size.");
// A failed read leaves that orchestrator out; the others still come back.
const plain = answer;
answer = (argv) => (argv[0] === "list" && argv.includes("e-other") ? { code: 1, stdout: "", stderr: "database is locked" } : plain(argv));
const partial = await loadSummaries(["O", "P"], "/beads");
assert.deepEqual([...partial.keys()], ["O"]);
answer = plain;

// liveHold: the bead as it is now, and its newest question.
assert.deepEqual(await liveHold("/beads", "b4"), { hold: "needs-user", question: { id: "c8", text: "Keep 30 or 90 days?\nIt doubles the size." } });
assert.deepEqual(await liveHold("/beads", "b2"), { hold: null, question: null });
assert.equal(await bdConfig("/beads", "jira.url"), "https://tracker.example");
assert.equal(await bdConfig("/beads", "unset.key"), "");

// newestEpic: created_at, then the id.
assert.equal(newestEpic([{ id: "a", created_at: at(1) }, { id: "b", created_at: at(2) }]).id, "b");
assert.equal(newestEpic([{ id: "a", created_at: at(1) }, { id: "b", created_at: at(1) }]).id, "b");
assert.equal(newestEpic([]), null);

console.log("agents-bd: ok");
