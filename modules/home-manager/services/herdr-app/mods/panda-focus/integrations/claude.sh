#!/bin/sh
# Loaded per launch: inside Herdr terminals the `claude` shim passes claude-plugin/ (--plugin-dir), whose hook runs this.
# Claude Code SessionStart hook: labels this Claude's herdr-core terminal with the line that resumes its session
# (`resume=claude --resume <id>`), so panda-focus can bring it back after a reboot. Runs again on /clear,
# /resume and compaction. Does nothing outside herdr-core or for sub-agents.
# After a compaction, a terminal labelled `orch-context=<script>` (an orchestrator or worker) also
# gets that script's output back in context, since compaction summarizes the session's state away.

input=$(cat)
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
case "$input" in *'"agent_id"'*) exit 0 ;; esac
id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p')
[ -n "$id" ] || exit 0
# `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
PATH="$PATH:$HOME/.local/bin"
hc label "$HC_TERMINAL_ID" "resume=claude --resume $id" >/dev/null || {
  echo "Herdr can't resume this session after a reboot: hc label failed" >&2
  exit 1
}

# Best effort from here: a missing jq or label only loses the reminder; a label naming a missing script says so.
case "$input" in *'"source"'*'"compact"'*) ;; *) exit 0 ;; esac
command -v jq >/dev/null || exit 0
script=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null | jq -r '.labels["orch-context"] // empty' 2>/dev/null)
[ -n "$script" ] || exit 0
# A directory is "executable" too: only a runnable file counts.
if [ -f "$script" ] && [ -x "$script" ]; then
  context=$("$script" 2>/dev/null) || exit 0
else
  context="Orchestrator context script missing: $script. Run status.sh --live before acting."
fi
[ -n "$context" ] || exit 0
printf '%s' "$context" | jq -Rs '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}'
