// panda-focus session integrations: after a compaction, an orchestrator terminal (label `orch-context=<script>`)
// gets the script's output back in context; every other session start only sets the resume label. Codex sets it
// only from the terminal's own foreground Codex; agy does too. Copilot skips sub-agents, as Claude does.
// Run: nix shell nixpkgs#nodejs nixpkgs#jq --command node --test modules/home-manager/services/herdr-app/tests/session-integrations.mjs
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { chmodSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const dir = join(fileURLToPath(new URL(".", import.meta.url)), "../mods/panda-focus/integrations");

// A fake `hc` that records calls and answers `get` with labels; `orchestrator` labels the fake context script.
function fixture(orchestrator) {
  const root = mkdtempSync(join(tmpdir(), "panda-session-"));
  const labels = orchestrator ? { "orch-context": join(root, "context.sh") } : { "orch-context": "/nonexistent" };
  writeFileSync(join(root, "labels.json"), JSON.stringify({ labels }));
  writeFileSync(join(root, "hc"), `#!/bin/sh\necho "$*" >> "${root}/calls"\n[ "$1" = get ] && cat "${root}/labels.json"\nexit 0\n`);
  writeFileSync(join(root, "context.sh"), `#!/bin/sh\necho "state for $HC_TERMINAL_ID"\n`);
  chmodSync(join(root, "hc"), 0o755);
  chmodSync(join(root, "context.sh"), 0o755);
  const env = { ...process.env, HC_TERMINAL_ID: "t1", HOME: root, PATH: `${root}:${process.env.PATH}` };
  return { root, env, calls: () => readFileSync(join(root, "calls"), "utf8") };
}

const claude = (f, source) =>
  execFileSync("sh", [join(dir, "claude.sh")], { env: f.env, input: JSON.stringify({ session_id: "abc-123", source }) }).toString();

test("claude: compaction on an orchestrator terminal injects the script output", () => {
  const f = fixture(true);
  const out = JSON.parse(claude(f, "compact"));
  assert.equal(out.hookSpecificOutput.hookEventName, "SessionStart");
  assert.equal(out.hookSpecificOutput.additionalContext, "state for t1");
  assert.match(f.calls(), /label t1 resume=claude --resume abc-123/);
});

test("claude: startup or a terminal without the label prints nothing", () => {
  const f = fixture(false);
  assert.equal(claude(f, "startup"), "");
  assert.equal(claude(f, "compact"), "");
  assert.match(f.calls(), /resume=claude --resume abc-123/);
});

// codex.sh's parent is this test process: it plays the terminal's foreground Codex, or a nested one.
const codex = (f, fg) => {
  writeFileSync(join(f.root, "labels.json"), JSON.stringify({ foreground: { pid: fg } }));
  execFileSync("sh", [join(dir, "codex.sh")], { env: f.env, input: JSON.stringify({ session_id: "01a1-ec05", source: "startup" }) });
  try {
    return f.calls();
  } catch {
    return "";
  }
};

test("codex: the terminal's own Codex labels its resume line", () => {
  assert.match(codex(fixture(false), process.pid), /label t1 resume=codex --no-daemon resume 01a1-ec05/);
});

test("codex: a nested codex exec leaves the label alone", () => {
  assert.doesNotMatch(codex(fixture(false), process.pid + 1), /label/);
});

// agy.sh's parent is this test process: it plays the terminal's foreground agy, or a nested one.
const agy = (f, fg) => {
  writeFileSync(join(f.root, "labels.json"), JSON.stringify({ foreground: { pid: fg } }));
  execFileSync("sh", [join(dir, "agy.sh")], { env: f.env, input: JSON.stringify({ conversationId: "ff97-8260", hookEventName: "SessionStart" }) });
  try {
    return f.calls();
  } catch {
    return "";
  }
};

test("agy: the terminal's own agy labels its resume line", () => {
  assert.match(agy(fixture(false), process.pid), /label t1 resume=agy --conversation=ff97-8260/);
});

test("agy: a nested agy leaves the label alone", () => {
  assert.doesNotMatch(agy(fixture(false), process.pid + 1), /label/);
});

const copilot = (f, input) => {
  execFileSync("sh", [join(dir, "copilot.sh")], { env: f.env, input: JSON.stringify(input) });
  try {
    return f.calls();
  } catch {
    return "";
  }
};

test("copilot: a session start labels its resume line", () => {
  assert.match(copilot(fixture(false), { session_id: "c0f1-0e", source: "startup" }), /label t1 resume=copilot --resume=c0f1-0e/);
});

test("copilot: a sub-agent leaves the label alone", () => {
  assert.doesNotMatch(copilot(fixture(false), { session_id: "c0f1-0e", agent_id: "a1" }), /label/);
});

test("agy and copilot: outside herdr they do nothing", () => {
  const f = fixture(false);
  const env = { ...f.env, HC_TERMINAL_ID: "" };
  execFileSync("sh", [join(dir, "agy.sh")], { env, input: JSON.stringify({ conversationId: "ff97-8260" }) });
  execFileSync("sh", [join(dir, "copilot.sh")], { env, input: JSON.stringify({ session_id: "c0f1-0e" }) });
  assert.throws(() => f.calls());
});

test("pi: the first turn after a compaction carries the script output, once", async () => {
  const f = fixture(true);
  const saved = { ...process.env };
  Object.assign(process.env, f.env);
  const handlers = {};
  try {
    const { default: init } = await import(`${pathToFileURL(join(dir, "pi.ts")).href}?${Date.now()}`);
    init({ on: (event, fn) => { handlers[event] = fn; } });
    assert.equal(await handlers.before_agent_start(), undefined);
    handlers.session_compact();
    const result = await handlers.before_agent_start();
    assert.deepEqual(result, { message: { customType: "herdr-orchestrator-state", content: "state for t1", display: false } });
    assert.equal(await handlers.before_agent_start(), undefined);
  } finally {
    process.env = saved;
  }
});
