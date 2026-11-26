#!/bin/sh
# Loaded per launch: inside Herdr terminals the `copilot` shim passes copilot-plugin/ (--plugin-dir), whose hook runs this.
# Copilot reads Claude Code plugin hooks, with Claude Code's input field names. SessionStart hook: labels this
# Copilot's herdr-core terminal with the line that resumes its session (`resume=copilot --resume=<id>`), so an
# orchestrator can revive it. Does nothing outside herdr-core or for sub-agents.

input=$(cat)
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
case "$input" in *'"agent_id"'*) exit 0 ;; esac
id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p')
[ -n "$id" ] || exit 0
# `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
PATH="$PATH:$HOME/.local/bin"
hc label "$HC_TERMINAL_ID" "resume=copilot --resume=$id" >/dev/null || {
  echo "Herdr can't resume this session: hc label failed" >&2
  exit 1
}
