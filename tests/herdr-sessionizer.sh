#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$(realpath "$0")")/../modules/home-manager/services/herdr-app/scripts/herdr-sessionizer.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/projects/sample.repo" "$tmp/work/org/repo"
export SESSIONIZER_PATHS="$tmp/projects" SESSIONIZER_DEEP_PATHS="$tmp/work"
export HERDR_PANE_ID='' HC_TERMINAL_SOCKET=test SESSIONIZER_TEST_LOG="$tmp/calls"
export PATH="$tmp/bin:$PATH"
export SESSIONIZER_TEST_SPACES='{"spaces":[]}'
cat > "$tmp/bin/herdr-app" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == ls ]]; then
  printf '%s\n' "$SESSIONIZER_TEST_SPACES"
else
  printf '%s\n' "$@" > "$SESSIONIZER_TEST_LOG"
fi
SH
chmod +x "$tmp/bin/herdr-app"

export FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE=/dev/null
FZF_DEFAULT_OPTS=--filter=sample.repo bash "$script"
[[ $(jq -r .name < <(tail -n 1 "$tmp/calls")) == sample_repo ]]
[[ $(jq -r .folder < <(tail -n 1 "$tmp/calls")) == "$tmp/projects/sample.repo" ]]
[[ $(head -n 2 "$tmp/calls" | tail -n 1) == space.new ]]

export SESSIONIZER_TEST_SPACES='{"spaces":[{"name":"org_repo","id":"existing-space"}]}'
bash "$script" "$tmp/work/org/repo"
[[ $(head -n 2 "$tmp/calls" | tail -n 1) == space.select ]]
[[ $(jq -r .id < <(tail -n 1 "$tmp/calls")) == existing-space ]]

rm "$tmp/calls"
FZF_DEFAULT_OPTS=--filter=no-such-project bash "$script"
[[ ! -e "$tmp/calls" ]]
printf 'PASS: fzf selection, directory naming, space creation/reuse, cancellation\n'
