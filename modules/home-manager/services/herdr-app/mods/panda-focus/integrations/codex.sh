#!/bin/sh
# Loaded per launch: inside Herdr terminals the `codex` shim passes this as a SessionStart hook (`-c hooks...`).
# Codex asks to trust it once (/hooks); the trust is kept in ~/.codex/config.toml.
# Labels this Codex's herdr-core terminal with the line that resumes its session
# (`resume=codex --no-daemon resume <id>`), so panda-focus can bring it back after a reboot. Codex starts a session
# on its first message, and again on /new. Does nothing outside herdr-core, or for a Codex that isn't the
# terminal's own program (`codex exec` run by another agent inherits the shim and the terminal id).

input=$(cat)
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p')
[ -n "$id" ] || exit 0
# `hc` lives in ~/.local/bin, which a terminal's PATH may lack.
PATH="$PATH:$HOME/.local/bin"
# The hook runs as a child of Codex itself: only the terminal's foreground Codex may label it.
# Without jq the check is skipped, as a nested `codex exec` is rare.
if command -v jq >/dev/null; then
  fg=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null | jq -r '.foreground.pid // empty' 2>/dev/null)
  [ -z "$fg" ] || [ "$fg" = "$PPID" ] || exit 0
fi
hc label "$HC_TERMINAL_ID" "resume=codex --no-daemon resume $id" >/dev/null || {
  echo "Herdr can't resume this session after a reboot: hc label failed" >&2
  exit 1
}
