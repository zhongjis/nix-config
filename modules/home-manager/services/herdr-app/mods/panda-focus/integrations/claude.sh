#!/bin/sh
# Installed by the Herdr app's panda-focus mod, which overwrites this file whenever its copy changes.
# Claude Code SessionStart hook: labels this Claude's herdr-core terminal with the line that resumes its session
# (`resume=claude --resume <id>`), so panda-focus can bring it back after a reboot. Runs again on /clear,
# /resume and compaction. Does nothing outside herdr-core or for sub-agents.

input=$(cat)
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
case "$input" in *'"agent_id"'*) exit 0 ;; esac
id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p')
[ -n "$id" ] || exit 0
# `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
PATH="$PATH:$HOME/.local/bin" hc label "$HC_TERMINAL_ID" "resume=claude --resume $id" >/dev/null || {
  echo "Herdr can't resume this session after a reboot: hc label failed" >&2
  exit 1
}
