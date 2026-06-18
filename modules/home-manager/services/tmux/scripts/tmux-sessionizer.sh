#!/usr/bin/env bash
# File: tmux-sessionizer

# Paths scanned one level deep: each direct child becomes a session.
DEFAULT_PATHS="$HOME/.config $HOME/personal $HOME/Documents"
# Paths using an org/repo layout: scanned two levels deep, so each repo
# (not the org) becomes a session.
DEFAULT_DEEP_PATHS="$HOME/work"

# Override defaults via SESSIONIZER_PATHS / SESSIONIZER_DEEP_PATHS if set.
shallow_paths=${SESSIONIZER_PATHS:-$DEFAULT_PATHS}
deep_paths=${SESSIONIZER_DEEP_PATHS:-$DEFAULT_DEEP_PATHS}

if [[ $# -eq 1 ]]; then
  selected="$1"
else
  selected=$(
    {
      for path in $shallow_paths; do
        [[ -d "$path" ]] && find "$path" -mindepth 1 -maxdepth 1 -type d
      done
      for path in $deep_paths; do
        [[ -d "$path" ]] && find "$path" -mindepth 2 -maxdepth 2 -type d
      done
    } | fzf
  )
fi

if [[ -z "$selected" ]]; then
  exit 0
fi

# Work repos live at <deep_path>/<org>/<repo>; name them org_repo to avoid
# collisions when two orgs share a repo name. Everything else uses basename.
selected_name=""
for path in $deep_paths; do
  if [[ "$selected" == "$path/"* ]]; then
    rel="${selected#"$path"/}"
    selected_name="${rel//\//_}"
    selected_name="${selected_name//./_}"
    break
  fi
done
[[ -z "$selected_name" ]] && selected_name=$(basename "$selected" | sed 's/\./_/g')
tmux_running=$(pgrep tmux)

if [[ -z "$TMUX" ]] && [[ -z "$tmux_running" ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
