// Assert-based checks for the herdr-nvim session miner port (see LICENSE-herdr-nvim).
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, mkdir, writeFile, appendFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { agentKind, piSlug, claudeSlugs, parseEtime, newestSince, parseLine, SessionFiles, readSession, discoverSession } from "../mods/filetree/agent-files.js";

// Same tool-call shapes/order as upstream session_pi_basic / session_claude_basic.
const pi = (name, path, timestamp = "2026-07-22T11:08:00.000Z") => JSON.stringify({ type: "message", timestamp,
  message: { content: [{ type: "toolCall", name, arguments: { path } }] } }) + "\n";
const claude = (name, path, timestamp = "2026-07-22T11:08:00.000Z") => JSON.stringify({ type: "assistant", timestamp,
  message: { content: [{ type: "tool_use", name, input: { file_path: path } }] } }) + "\n";
assert.equal(piSlug("/Users/adamchmara"), "--Users-adamchmara--");
assert.equal(piSlug("C:\\repo"), "--C--repo--");
assert.deepEqual(claudeSlugs("/private/tmp/nv9076-e2e.apps/agent"), ["-private-tmp-nv9076-e2e.apps-agent", "-private-tmp-nv9076-e2e-apps-agent"]);
assert.equal(agentKind("pi"), "pi");
assert.equal(agentKind("claude-code"), "claude");
assert.equal(agentKind("pip"), null);
assert.equal(parseEtime("  05:07\n"), 307000);
assert.equal(parseEtime("2-00:00:01"), 172801000);
assert.equal(parseEtime(""), null);
assert.equal(newestSince([{ path: "old", mtime: 100000 }, { path: "resumed", mtime: 700000 }], 400000), "resumed");
assert.equal(newestSince([{ path: "old", mtime: 100000 }], 400000), null);

for (const [kind, line, read, write, edit, bash] of [["pi", pi, "read", "write", "edit", "bash"], ["claude", claude, "Read", "Write", "Edit", "Bash"]]) {
  const miner = new SessionFiles({ kind, cwd: "/repo" });
  miner.append("not json\n" + line(read, "/repo/src/lib.rs") + line(bash, "/repo/ignored")
    + line(write, "/repo/src/new_mod.rs", "2026-07-22T11:08:20Z") + line(edit, "src/./lib.rs", "2026-07-22T11:08:30Z"));
  const touches = miner.history().reverse();
  assert.deepEqual(touches.map((t) => t.abs), ["/repo/src/lib.rs", "/repo/src/new_mod.rs"]);
  assert.equal(touches[0].newlyCreated, false);
  assert.equal(touches[0].wasEdited, true);
  assert.equal(touches[1].newlyCreated, true);
  miner.append(line(read, "src/new_mod.rs", "2026-07-22T11:08:40Z"));
  assert.equal(miner.history().at(-1).newlyCreated, true);
  assert.equal(miner.history().at(-1).wasEdited, true);
  const since = new SessionFiles({ kind, cwd: "/repo", since: Date.parse("2026-07-22T12:00:00Z") });
  since.append(line(read, "/repo/earlier"));
  assert.deepEqual(since.history(), []);
}
assert.deepEqual(parseLine("{", "pi"), []);
assert.deepEqual(parseLine("null", "pi"), []);
assert.equal(parseLine(pi("read", "@/repo/a.rs"), "pi")[0].path, "/repo/a.rs");
for (const name of ["MultiEdit", "NotebookEdit"]) assert.equal(parseLine(claude(name, "/repo/book"), "claude")[0].op, "edit");
assert.equal(parseLine(JSON.stringify({ type: "message", message: { content: [{ type: "toolCall", name: "edit", arguments: { file_path: "/repo/mod.rs", edits: [] } }] } }), "pi")[0].op, "edit");

const run = promisify(execFile);
const exec = async (command, args) => ({ code: 0, ...await run(command, args) });
const dir = await mkdtemp(join(tmpdir(), "filetree-session-"));
try {
  const cwd = join(dir, "repo.with-dot"), root = join(dir, "agent");
  await mkdir(cwd);
  const sessionDir = join(root, "sessions", piSlug(cwd));
  await mkdir(sessionDir, { recursive: true });
  const path = join(sessionDir, "2026-07-22_session-id.jsonl");
  const initial = pi("read", "日本語.rs");
  await writeFile(path, initial);
  // IO injection only selects an isolated config root, not a mock transcript reader.
  const isolatedExec = async (command, args) => ({ code: 0, ...await run(command, args, { env: { ...process.env, PI_CODING_AGENT_DIR: root } }) });
  const source = { kind: "pi", cwd, since: Date.now() - 1000, on: null, path };
  assert.equal(await discoverSession(isolatedExec, source), path);
  const miner = new SessionFiles({ kind: "pi", cwd });
  assert.equal((await readSession(exec, source, miner)).length, 1);
  assert.equal(miner.offset, Buffer.byteLength(initial));
  assert.deepEqual(await readSession(exec, source, miner), []);
  const next = pi("write", "fresh.rs");
  await appendFile(path, next.slice(0, -1));
  assert.deepEqual(await readSession(exec, source, miner), []);
  await appendFile(path, "\n");
  assert.equal((await readSession(exec, source, miner))[0].newlyCreated, true);
  assert.equal(miner.offset, Buffer.byteLength(initial + next));
} finally { await rm(dir, { recursive: true, force: true }); }
console.log("filetree-agent-files: passed (pi/Claude mining, ordering, since-start, discovery and incremental IO)");
