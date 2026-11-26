#!/bin/sh
# Loaded by the herdr-app-session agy plugin, which Home Manager links into agy's plugins folder (agy has no
# per-launch plugin flag). agy SessionStart hook: labels this agy's herdr-core terminal with the line that resumes
# its conversation (`resume=agy --conversation=<id>`), so an orchestrator can revive it. Does nothing outside
# herdr-core, or for an agy that isn't the terminal's own program (one run by another agent inherits the terminal id).

input=$(cat)
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
id=$(printf '%s' "$input" | sed -n 's/.*"conversationId"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p')
[ -n "$id" ] || exit 0
# `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
PATH="$PATH:$HOME/.local/bin"
# The hook runs as a child of agy itself: only the terminal's foreground agy may label it.
# Without jq the check is skipped, as a nested agy is rare.
if command -v jq >/dev/null; then
  fg=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null | jq -r '.foreground.pid // empty' 2>/dev/null)
  [ -z "$fg" ] || [ "$fg" = "$PPID" ] || exit 0
fi
hc label "$HC_TERMINAL_ID" "resume=agy --conversation=$id" >/dev/null || {
  echo "Herdr can't resume this conversation: hc label failed" >&2
  exit 1
}
