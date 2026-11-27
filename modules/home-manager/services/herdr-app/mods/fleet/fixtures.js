// A made-up session for the panel when live beads aren't wanted (fleet.fixture; "Sample" in the header). Shaped as
// shared bd.js loadSession returns a Session, so shared tasks.js buildTasks reads it as it reads a live one.
// One epic, six tasks, one per state: merged and settled, in review with a PR, your turn on a question, waiting on
// a prerequisite, waiting for a slot, and one with a hibernated worker. Times count back from `now`, so ages read
// sensibly; terminal addresses are fake (tfx*). Names and tickets are generic.

const ref = (key) => `https://tracker.example/browse/${key}`;
const at = (now, minutes) => new Date(now - minutes * 60000).toISOString();

export function fixtureSession(now) {
  let n = 0;
  const c = (minutes, author, text) => ({ id: `fx-c${++n}`, author, created_at: at(now, minutes), text });
  const epic = {
    id: "fx-1", title: "orch: sample session", status: "in_progress", external_ref: ref("ABC-10"), labels: [],
    metadata: { session: "tfx0" },
  };
  const task = (id, key, title, status, extra = {}) => ({
    id, title, status, assignee: extra.assignee, external_ref: ref(key), labels: [], metadata: extra.metadata ?? {},
  });
  const beads = [
    task("fx-1.1", "ABC-11", "Vendor the beads skill into the catalog", "closed", {
      assignee: "w-abc-11-vendor", metadata: { review_round: "1", pr_url: "https://github.com/acme/skills/pull/412", merged_sha: "9f3d2a7c1e0b" } }),
    task("fx-1.2", "ABC-12", "Switch the orchestration copy to bd events", "in_progress", {
      assignee: "w-abc-12-events", metadata: { review_round: "1", pr_url: "https://github.com/acme/skills/pull/415" } }),
    task("fx-1.3", "ABC-13", "Pick the retention window for closed beads", "blocked", {
      assignee: "w-abc-13-retention", metadata: { blocked_reason: "needs-user" } }),
    task("fx-1.4", "ABC-14", "Read todos from bd in the editor config", "open"),
    task("fx-1.5", "ABC-15", "Document the review rounds", "open"),
    task("fx-1.6", "ABC-16", "Trim the session start hook", "in_progress", { assignee: "w-abc-16-hook" }),
  ];
  const review = { id: "fx-1.2.r1", title: "Review r1: ABC-12", status: "closed", assignee: "r-abc-12-events", labels: [], metadata: {} };
  const comments = {
    "fx-1": [c(700, "o-sample", "event=mode flags=--auto max=2")],
    "fx-1.1": [
      c(660, "o-sample", "event=dispatched agent=w-abc-11-vendor terminal=tfx1 kind=work"),
      c(600, "w-abc-11-vendor", "event=report kind=pr-opened pr=https://github.com/acme/skills/pull/412 head=4be1c09aa1"),
      c(560, "o-sample", "event=ready pr=https://github.com/acme/skills/pull/412 head=4be1c09aa1"),
      c(500, "o-sample", "event=merged merged_sha=9f3d2a7c1e0b"),
      c(480, "o-sample", "event=settled result=succeeded"),
    ],
    "fx-1.2": [
      c(420, "o-sample", "event=dispatched agent=w-abc-12-events terminal=tfx3 kind=work"),
      c(300, "w-abc-12-events", "event=report kind=pushed head=02e0d60b1 pr=https://github.com/acme/skills/pull/415"),
      c(280, "o-sample", "event=re-instructed agent=w-abc-12-events terminal=tfx3\n\nAddress the review: keep the old event names readable."),
      c(120, "w-abc-12-events", "event=report kind=ready-local head=a1b2c3d4e"),
      c(110, "o-sample", "event=dispatched agent=r-abc-12-events terminal=tfx4 kind=review round=1"),
      c(40, "o-sample", "event=decided by=orchestrator q=Squash or keep the three commits? a=Squash: the history is noise."),
      c(9, "w-abc-12-events", "event=report kind=pushed head=02e0d60b1"),
    ],
    "fx-1.2.r1": [c(110, "o-sample", "event=dispatched agent=r-abc-12-events terminal=tfx4 round=1")],
    "fx-1.3": [
      c(300, "o-sample", "event=dispatched agent=w-abc-13-retention terminal=tfx5 kind=work"),
      c(150, "w-abc-13-retention", "event=report kind=blocked"),
      c(145, "o-sample", "event=blocked reason=needs-user\nKeep closed beads 30 or 90 days? 90 doubles the database size.\nThe 30 day option drops old review rounds first."),
    ],
    "fx-1.4": [c(5, "o-sample", "event=queued after=fx-1.2")],
    "fx-1.5": [c(5, "o-sample", "event=queued needs=slot")],
    "fx-1.6": [c(200, "o-sample", "event=dispatched agent=w-abc-16-hook terminal=tfx6 kind=work")],
  };
  return {
    epic,
    mode: { flags: "--auto", max: 2, at: now - 700 * 60000 },
    beads,
    deps: {
      "fx-1.4": [{ id: "fx-1.2", type: "blocks", status: "in_progress" }],
      "fx-1.5": [{ id: "fx-1.1", type: "blocks", status: "closed" }],
    },
    reviews: { "fx-1.2": [review] },
    comments,
  };
}

// The terminals the sample's workers run in: one working, one at its prompt, a finished reviewer.
export function fixtureTerms() {
  const live = (address, name, status) => ({ address, name, state: "live", status, labels: { orch: "tfx0" }, program: null });
  return [
    live("tfx3", "w-abc-12-events", "working"),
    live("tfx4", "r-abc-12-events", "idle"),
    live("tfx5", "w-abc-13-retention", "idle"),
  ];
}

// A worker asleep (shared "panda-focus.hibernated" row shape).
export const fixtureHibernated = (now) => [{
  address: "tfx6", name: "w-abc-16-hook", parent: "tfx0", space: "sp1", cwd: "/tmp/sample", line: "claude",
  at: now - 90 * 60000, title: "w-abc-16-hook", program: null,
}];
