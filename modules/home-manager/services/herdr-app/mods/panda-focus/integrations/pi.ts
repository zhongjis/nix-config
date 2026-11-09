// Installed by the Herdr app's panda-focus mod, which overwrites this file whenever its copy changes.
// Labels this Pi's herdr-core terminal with the line that resumes its session (`resume=pi --session <id>`),
// so panda-focus can bring it back after a reboot. Runs again on /new and /resume. Does nothing outside herdr-core.
// @ts-nocheck

import { execFile } from "node:child_process";

export default function (pi) {
  const terminal = process.env.HC_TERMINAL_ID;
  if (!terminal) return;
  pi.on("session_start", (_event, ctx) => {
    // Headless runs (RPC, JSON, print) inherit the terminal id from their parent; only the TUI owns the pane.
    if (ctx?.mode !== "tui") return;
    let id;
    try {
      id = ctx?.sessionManager?.getSessionId?.();
    } catch {
      return;
    }
    if (typeof id === "string" && id) execFile("hc", ["label", terminal, `resume=pi --session ${id}`], () => {});
  });
}
