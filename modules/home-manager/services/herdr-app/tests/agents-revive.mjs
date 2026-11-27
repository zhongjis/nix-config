// The shared revive path (mods/shared/revive.js), used by the Agents panel and the sub-agents popup: a finished worker
// comes back with its launch contract (argv and its env, name, cwd, parent, labels), and a failed start keeps the old
// terminal and its resume label. A fake `hc` records every call. Made-up data only.
// Run: node modules/home-manager/services/herdr-app/tests/agents-revive.mjs
import assert from "node:assert/strict";
import { agentLine, envOf, plan, resumeOf, revive, RUNTIME } from "../mods/shared/revive.js";

// A worker as start-worker.sh launches it, after the sidebar hibernated it.
const finished = (extra = {}) => ({
  address: "t7", name: "w-abc-12-keys", state: "finished", cwd: "/work/abc-12", parent: "t1", notify: false, die_with_parent: false,
  argv: ["env", "PATH=/shims:/usr/bin", "AGENT_BROWSER_NAMESPACE=w-abc-12-keys", "BEADS_ACTOR=w-abc-12-keys", "ORCH_BEAD=bd-1",
    "BEADS_DIR=/data/my beads", "BEADS_DOLT_SHARED_SERVER=1", "claude", "Load the orchestrated-worker skill …"],
  status: { app: "claude-code", state: "idle" },
  labels: {
    orch: "t1", "orch-context": "/skills/worker-context.sh", space: "s-3", custom: "kept",
    resume: "env AGENT_BROWSER_NAMESPACE=w-abc-12-keys BEADS_ACTOR=w-abc-12-keys ORCH_BEAD=bd-1 claude --resume 0000-1111",
    "resume.pid": "", hibernated: "1795600000000", hibernate: "ok", "orch.in": "1795600000000:dispatched", where: "x",
    "herdr.space": "s-3", "herdr.tab": "tb1", settled: "", snoozed: "",
  },
  ...extra,
});

// envOf / agentLine
assert.deepEqual(envOf(["env", "A=1", "B=two words", "pi", "--session", "x"]), ["A=1", "B=two words"]);
assert.deepEqual(envOf(["pi"]), []);
assert.deepEqual(envOf(undefined), []);
assert.deepEqual(agentLine("env A=1 B=2 claude --resume 0000"), ["claude", "--resume", "0000"]);
assert.deepEqual(agentLine("pi --session s1"), ["pi", "--session", "s1"]);
assert.deepEqual(agentLine(""), []);
for (const k of ["resume", "resume.pid", "hibernated", "hibernate", "settled", "snoozed", "orch.in", "where", "herdr.space"]) assert.ok(RUNTIME.test(k), k);
for (const k of ["orch", "orch-context", "space", "custom"]) assert.ok(!RUNTIME.test(k), k);

// The plan: argv with the old env whole (PATH with the shims, a value with a space), every non-runtime label, the
// name, cwd, parent while it is live, notify and outlive settings, hibernate=ok as it was.
const p = plan(finished(), { parentLive: (a) => a === "t1" });
assert.deepEqual(p.args, [
  "run", "--bg", "--json", "--cwd", "/work/abc-12", "--name", "w-abc-12-keys", "--parent", "t1", "--outlive-parent", "--no-notify",
  "--label", "orch=t1", "--label", "orch-context=/skills/worker-context.sh", "--label", "space=s-3", "--label", "custom=kept",
  "--label", "hibernate=ok",
  "--", "env", "PATH=/shims:/usr/bin", "AGENT_BROWSER_NAMESPACE=w-abc-12-keys", "BEADS_ACTOR=w-abc-12-keys", "ORCH_BEAD=bd-1",
  "BEADS_DIR=/data/my beads", "BEADS_DOLT_SHARED_SERVER=1", "claude", "--resume", "0000-1111",
]);
// Orchestrated (orch-context names the skill's worker-context.sh): the skill's own launch checks run first, with the
// terminal's env, beside that script.
assert.deepEqual(p.check.argv, ["PATH=/shims:/usr/bin", "AGENT_BROWSER_NAMESPACE=w-abc-12-keys", "BEADS_ACTOR=w-abc-12-keys", "ORCH_BEAD=bd-1",
  "BEADS_DIR=/data/my beads", "BEADS_DOLT_SHARED_SERVER=1", "/skills/start-worker.sh", "w-abc-12-keys", "/work/abc-12", "bd-1",
  "--kind", "claude", "--resume", "0000-1111", "--check"]);
// Not orchestrated: no check. Orchestrated but without a bead or a readable session: refused, nothing to run.
assert.equal(plan(finished({ labels: { resume: finished().labels.resume, hibernate: "ok" } })).check, null);
// An orch label without the skill's script: its checks can't run, so it isn't revived here.
assert.match(plan(finished({ labels: { ...finished().labels, "orch-context": undefined } })).error, /launch checks/);
assert.match(plan(finished({ argv: ["env", "PATH=/x", "claude"], labels: { ...finished().labels, resume: "claude --resume 0000" } })).error, /launch checks/);
assert.match(plan(finished({ labels: { ...finished().labels, resume: "claude" } })).error, /launch checks/);
assert.deepEqual(resumeOf(["pi", "--session", "s1"]), { kind: "pi", session: "s1" });
assert.deepEqual(resumeOf(["agy", "--conversation=c9"]), { kind: "agy", session: "c9" });
assert.deepEqual(resumeOf(["copilot", "--resume=k2"]), { kind: "copilot", session: "k2" });
assert.deepEqual(resumeOf(["codex", "--no-daemon", "resume", "u1"]), { kind: "codex", session: "u1" });
assert.equal(resumeOf(["vim"]), null);

// A parent that ended is not named; a terminal that never opted in stays out of hibernation; Codex never opts in.
assert.ok(!plan(finished(), { parentLive: () => false }).args.includes("--parent"));
assert.ok(!plan(finished({ labels: { ...finished().labels, hibernate: undefined } })).args.includes("hibernate=ok"));
const codex = plan(finished({ status: { app: "codex" }, labels: { ...finished().labels, resume: "codex --no-daemon resume 2222" } }));
assert.ok(!codex.args.includes("hibernate=ok"), "never on Codex");
assert.ok(!plan(finished({ status: {}, labels: { ...finished().labels, resume: "codex resume 2222" } })).args.includes("hibernate=ok"));
// A shell recovered after a reboot has no env in its argv: the resume label's own prefix comes back instead.
const shell = plan(finished({ argv: ["/bin/zsh", "-l"] }));
assert.deepEqual(shell.args.slice(shell.args.indexOf("--") + 1), ["env", "AGENT_BROWSER_NAMESPACE=w-abc-12-keys", "BEADS_ACTOR=w-abc-12-keys",
  "ORCH_BEAD=bd-1", "claude", "--resume", "0000-1111"]);
// No plan for a live terminal, one without a resume line, or one with no folder.
assert.equal(plan(finished({ state: "live" })).error, "It is still running.");
assert.equal(plan(finished({ labels: { orch: "t1" } })).error, "It has no resume line.");
assert.equal(plan(finished({ cwd: null })).error, "Its folder is unknown.");
assert.equal(plan(null).error, "The terminal is gone.");

// revive: the replacement starts first; only then the finished terminal goes.
// The launch check: passes by default; `refuse` makes it fail as start-worker.sh does.
const checks = [];
const exec = (refuse) => async (cmd, args) => {
  checks.push([cmd, args]);
  return refuse ? { code: 3, stdout: "", stderr: `${refuse}\n` } : { code: 0, stdout: "", stderr: "" };
};
function fakeHc(term, { run = { code: 0, stdout: JSON.stringify({ address: "t9" }), stderr: "" } } = {}) {
  const calls = [];
  const hc = async (args) => {
    calls.push(args);
    if (args[0] === "get") return term ? { code: 0, stdout: JSON.stringify(term), stderr: "" } : { code: 1, stdout: "", stderr: "no such terminal" };
    if (args[0] === "run") return run;
    return { code: 0, stdout: "", stderr: "" };
  };
  return { hc, calls };
}
{
  const f = fakeHc(finished());
  const res = await revive("t7", { hc: f.hc, exec: exec(), parentLive: () => true });
  assert.deepEqual(res, { ok: true, address: "t9" });
  assert.deepEqual(f.calls.map((c) => c[0]), ["get", "run", "rm"]);
  assert.deepEqual(f.calls[2], ["rm", "t7"]);
}
// A failed start keeps the old terminal (no rm) and so its resume label.
{
  const f = fakeHc(finished(), { run: { code: 1, stdout: "", stderr: "name w-abc-12-keys is taken" } });
  const res = await revive("t7", { hc: f.hc, exec: exec(), parentLive: () => true });
  assert.deepEqual(res, { ok: false, error: "name w-abc-12-keys is taken" });
  assert.ok(!f.calls.some((c) => c[0] === "rm" || c[0] === "label"), "nothing removed, no label touched");
}
// A start that answers without an address may have launched: the old terminal stays too.
{
  const f = fakeHc(finished(), { run: { code: 0, stdout: "not json", stderr: "" } });
  const res = await revive("t7", { hc: f.hc, exec: exec(), parentLive: () => true });
  assert.equal(res.ok, false);
  assert.ok(!f.calls.some((c) => c[0] === "rm"));
}
// Gone, or still running: nothing runs.
{
  const f = fakeHc(null);
  assert.deepEqual(await revive("t7", { hc: f.hc, exec: exec(), parentLive: () => true }), { ok: false, error: "no such terminal" });
  const g = fakeHc(finished({ state: "live" }));
  assert.equal((await revive("t7", { hc: g.hc, exec: exec(), parentLive: () => true })).ok, false);
  assert.deepEqual(g.calls.map((c) => c[0]), ["get"]);
}
// The new one started but the old one couldn't be removed: revived, with a warning.
{
  const f = fakeHc(finished());
  const hc = async (args) => (args[0] === "rm" ? { code: 1, stdout: "", stderr: "busy" } : f.hc(args));
  assert.deepEqual(await revive("t7", { hc, exec: exec(), parentLive: () => true }), { ok: true, address: "t9", warning: "busy" });
}

// The launch checks refuse (a reviewer whose review bead closed, a worker no longer assigned): nothing starts.
{
  const f = fakeHc(finished());
  checks.length = 0;
  const res = await revive("t7", { hc: f.hc, exec: exec("review bead bd-1 is not assigned in progress to r-x"), parentLive: () => true });
  assert.deepEqual(res, { ok: false, error: "The orchestration checks refused it: review bead bd-1 is not assigned in progress to r-x" });
  assert.deepEqual(f.calls.map((c) => c[0]), ["get"], "no run, no rm");
  assert.equal(checks[0][0], "/usr/bin/env");
  assert.equal(checks[0][1].at(-1), "--check");
}
// A terminal that isn't orchestrated runs no check.
{
  const f = fakeHc(finished({ labels: { resume: "pi --session s1" } }));
  checks.length = 0;
  assert.equal((await revive("t7", { hc: f.hc, exec: exec("never"), parentLive: () => true })).ok, true);
  assert.equal(checks.length, 0);
}

console.log("agents-revive: ok");
