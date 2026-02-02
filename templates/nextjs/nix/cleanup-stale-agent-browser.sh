#!/usr/bin/env bash
# Cleanup stale agent-browser daemons from different nix store paths.
#
# The agent-browser daemon persists in the background and caches the
# PLAYWRIGHT_BROWSERS_PATH from when it was started. When the nix store
# path changes (e.g., after flake update), the old daemon continues using
# stale browser paths, causing version mismatches.
#
# This script kills only daemons from DIFFERENT store paths, preserving
# daemons from other projects that may be using their own agent-browser.
#
# Usage: cleanup-stale-agent-browser.sh <current-agent-browser-store-path>

set -euo pipefail

current_agent_browser_path="${1:-}"

if [[ -z "$current_agent_browser_path" ]]; then
  echo "Usage: $0 <current-agent-browser-store-path>" >&2
  exit 1
fi

daemon_pids=$(pgrep -f "daemon.js" 2>/dev/null || true)

if [[ -z "$daemon_pids" ]]; then
  exit 0
fi

stale_pids=""

for pid in $daemon_pids; do
  [[ -d "/proc/$pid" ]] || continue
  
  cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
  
  if [[ "$cmdline" != *"agent-browser"* ]]; then
    continue
  fi
  
  if [[ "$cmdline" != *"$current_agent_browser_path"* ]]; then
    stale_pids="$stale_pids $pid"
  fi
done

stale_pids="${stale_pids# }"

if [[ -n "$stale_pids" ]]; then
  echo "Killing stale agent-browser daemons from old nix store paths: $stale_pids"
  for pid in $stale_pids; do
    kill "$pid" 2>/dev/null || true
  done
fi
