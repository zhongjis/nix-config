#!/usr/bin/env bash
# File: herdr-sessionizer — herdr port of tmux-sessionizer
# Create or switch to a herdr workspace per project directory, from any space.

# Default paths if SESSIONIZER_PATHS is not set
DEFAULT_PATHS="$HOME/.config $HOME/personal $HOME/work $HOME/Documents"

if [[ $# -eq 1 ]]; then
  selected="$1"
else
  # Use SESSIONIZER_PATHS if set, otherwise use default paths
  paths=${SESSIONIZER_PATHS:-$DEFAULT_PATHS}

  # Convert space-separated paths to find arguments
  find_args=()
  for path in $paths; do
    if [[ -d "$path" ]]; then
      find_args+=("$path")
    fi
  done

  if [[ ${#find_args[@]} -eq 0 ]]; then
    echo "No valid paths found in SESSIONIZER_PATHS"
    exit 1
  fi

  selected=$(find "${find_args[@]}" -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z "$selected" ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | sed 's/\./_/g')

# Reuse an existing workspace with this label, otherwise create one.
existing=$(herdr workspace list 2>/dev/null |
  jq -r --arg n "$selected_name" \
    '.result.workspaces[]? | select(.label == $n) | .workspace_id' |
  head -n1)

if [[ -n "$existing" ]]; then
  herdr workspace focus "$existing"
else
  herdr workspace create --cwd "$selected" --label "$selected_name" --focus
fi
