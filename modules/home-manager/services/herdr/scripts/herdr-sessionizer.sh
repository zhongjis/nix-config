#!/usr/bin/env bash
# File: herdr-sessionizer — herdr port of tmux-sessionizer
# Create or switch to a herdr workspace per project directory, from any space.

# Paths scanned one level deep: each direct child becomes a workspace.
DEFAULT_PATHS="$HOME/.config $HOME/personal $HOME/Documents"
# Paths using an org/repo layout: scanned two levels deep, so each repo
# (not the org) becomes a workspace.
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

# herdr TUI panes export HERDR_PANE_ID; herdr-app terminals only get
# herdr-core's HC_* vars. Outside both, default to the TUI.
if [[ -z "$HERDR_PANE_ID" && -n "$HC_TERMINAL_SOCKET" ]] && command -v herdr-app >/dev/null; then
  # Reuse an existing space with this name, otherwise create one.
  existing=$(herdr-app ls 2>/dev/null |
    jq -r --arg n "$selected_name" '.spaces[]? | select(.name == $n) | .id' |
    head -n1)

  if [[ -n "$existing" ]]; then
    herdr-app do space.select "$(jq -nc --arg id "$existing" '{id: $id}')" >/dev/null
  else
    herdr-app do space.new "$(jq -nc --arg n "$selected_name" --arg f "$selected" '{name: $n, folder: $f}')" >/dev/null
  fi
  exit
fi

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
