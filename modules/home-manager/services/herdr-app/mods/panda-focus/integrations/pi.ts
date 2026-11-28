// Loaded per launch: inside Herdr terminals the `pi` shim passes this file with `-e`.
// Labels this Pi's herdr-core terminal with the line that resumes its session (`resume=pi --session <id>`),
// so panda-focus can bring it back after a reboot. Runs again on /new and /resume. Does nothing outside herdr-core.
// It also labels the current model (`model=<provider>/<id>`), refreshed on every model switch.
// After a compaction, a terminal labelled `orch-context=<script>` (an orchestrator or worker) also
// gets that script's output back in context on its next turn, since compaction summarizes the session's state away.
// A script that is missing or not executable is named instead.
// @ts-nocheck

import { execFile } from "node:child_process";
import { accessSync, constants, statSync } from "node:fs";
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
    labelModel(ctx?.model);
  });

  // Best effort: `model=<provider>/<id>` lets an orchestrator read this Pi's model family without the screen.
  // Restoring a session fires no model_select, so session_start labels the restored model too.
  const labelModel = (model) => {
    if (model?.provider && model?.id) execFile("hc", ["label", terminal, `model=${model.provider}/${model.id}`], { env }, () => {});
  };
  pi.on("model_select", (event, ctx) => {
    if (ctx?.mode === "tui") labelModel(event?.model);
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
    let runnable = true;
    try {
      // A directory passes X_OK too: only a runnable file counts.
      if (!statSync(script).isFile()) throw new Error("not a file");
      accessSync(script, constants.X_OK);
    } catch {
      runnable = false;
    }
    const content = runnable
      ? (await run(script, [], env)).trim()
      : `Orchestrator context script missing: ${script}. Run status.sh --live before acting.`;
    if (content) return { message: { customType: "herdr-orchestrator-state", content, display: false } };
  });
}
