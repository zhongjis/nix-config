#!/usr/bin/env bash
# File: tmux-sessionizer

# Default paths if SESSIONIZER_PATHS is not set
DEFAULT_PATHS="$HOME/.config $HOME/personal $HOME/work"

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
tmux_running=$(pgrep tmux)

if [[ -z "$TMUX" ]] && [[ -z "$tmux_running" ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
