// Loaded per launch: inside Herdr terminals the `pi` shim passes this file with `-e`.
// Labels this Pi's herdr-core terminal with the line that resumes its session (`resume=pi --session <id>`),
// so panda-focus can bring it back after a reboot. Runs again on /new and /resume. Does nothing outside herdr-core.
// After a compaction, a terminal labelled `orch-context=<script>` (an orchestrate-using-herdr-app orchestrator) also
// gets that script's output back in context on its next turn, since compaction summarizes the orchestrator's state away.
// @ts-nocheck

import { execFile } from "node:child_process";
import { homedir } from "node:os";

const run = (file, args, env) =>
  new Promise((resolve) => execFile(file, args, { env, timeout: 10_000 }, (error, stdout) => resolve(error ? "" : stdout)));

export default function (pi) {
  const terminal = process.env.HC_TERMINAL_ID;
  if (!terminal) return;
  // `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
  const env = { ...process.env, PATH: `${process.env.PATH ?? ""}:${homedir()}/.local/bin` };
  pi.on("session_start", (_event, ctx) => {
    // Headless runs (RPC, JSON, print) inherit the terminal id from their parent; only the TUI owns the pane.
    if (ctx?.mode !== "tui") return;
    let id;
    try {
      id = ctx?.sessionManager?.getSessionId?.();
    } catch {
      return;
    }
    if (typeof id === "string" && id) execFile("hc", ["label", terminal, `resume=pi --session ${id}`], { env }, (error) => {
      if (error) ctx.ui?.notify?.(`Herdr can't resume this session after a reboot: ${error.message}`, "warning");
    });
  });

  // Best effort: a missing label, script or hc only loses the reminder.
  let compacted = false;
  pi.on("session_compact", () => {
    compacted = true;
  });
  pi.on("before_agent_start", async () => {
    if (!compacted) return;
    compacted = false;
    let script;
    try {
      script = JSON.parse(await run("hc", ["get", terminal, "--json"], env))?.labels?.["orch-context"];
    } catch {
      return;
    }
    if (!script) return;
    const content = (await run(script, [], env)).trim();
    if (content) return { message: { customType: "herdr-orchestrator-state", content, display: false } };
  });
}
