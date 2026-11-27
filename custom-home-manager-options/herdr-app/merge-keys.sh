#!/usr/bin/env bash
# Merge the Nix-managed keys into the live keys.json and prune what Nix wrote before and no longer does.
# Usage: merge-keys.sh <jq> <live keys.json> <manifest> <nix keys.json>
# The manifest is {"managed": [[section, key, value], ...]}: the last value Nix wrote per path. A path leaves the
# live file only when Nix dropped it and the live value still equals the managed value (a rebind stays). An old
# manifest is a list of [section, key] pairs without values: an unknown value is kept (it may be a rebind); only the
# legacy entries below, whose values are known, prune.
# Pruning and merging are one validated write; any failure warns, changes nothing and keeps the old manifest
# so the next activation retries. Always exits 0 so activation continues.
set -u
jq=$1 target=$2 manifest=$3 nix=$4

# What Nix wrote into keys.json before the manifest existed (both platforms' keys; absent ones prune nothing).
legacy='[
  ["mod:fleet","ctrl-shift-a","fleet.toggle"],
  ["mod:fleet","cmd-shift-a","fleet.toggle"],
  ["layout:herdr-fleet","cmd-shift-s","panda-focus.settle"],
  ["layout:herdr-fleet","ctrl-shift-s","panda-focus.settle"],
  ["layout:herdr-fleet","ctrl-shift-a",{"command":"layout.select","args":{"stack":"work-switch","child":"fleet"}}],
  ["layout:herdr-fleet","cmd-shift-a",{"command":"layout.select","args":{"stack":"work-switch","child":"fleet"}}],
  ["layout:herdr-tui","cmd-shift-s","tui-focus.settle"],
  ["layout:herdr-tui","ctrl-shift-s","tui-focus.settle"]
]'

tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT
fail() {
  echo "herdr-app: keys.json not updated ($1); the next activation retries" >&2
  exit 0
}

if [ -s "$manifest" ]; then
  "$jq" -c . "$manifest" >"$tmp/old" 2>/dev/null || fail "unreadable manifest"
else
  echo '[]' >"$tmp/old"
fi

# nothing Nix writes and no live file: nothing to do
if [ ! -s "$target" ]; then
  "$jq" -e 'length > 0' "$nix" >/dev/null 2>&1 || exit 0
fi

"$jq" '
  [to_entries[] | select(.value | type == "object") | .key as $s | .value | to_entries[] | [$s, .key, .value]]
  | {managed: .}' "$nix" >"$tmp/manifest" 2>/dev/null || fail "unreadable Nix keys"

if [ -s "$target" ]; then
  "$jq" --slurpfile old "$tmp/old" --slurpfile nix "$nix" --argjson legacy "$legacy" '
    if type != "object" then error("keys.json is not an object") else . end
    | . as $live
    | $nix[0] as $n
    | [$n | to_entries[] | select(.value | type == "object") | .key as $s | .value | keys_unsorted[] | [$s, .]] as $newp
    | (if ($old[0] | type) == "object" then $old[0].managed else $legacy end) as $olde
    | [$olde[]
        | select(length == 3)
        | select(. as $e | any($newp[]; . == [$e[0], $e[1]]) | not)
        | select(. as $e | ($live[$e[0]] | type) == "object" and ($live[$e[0]] | has($e[1])))
        | select(. as $e | $live[$e[0]][$e[1]] == $e[2])] as $prune
    | reduce $prune[] as $e ($live; delpaths([[$e[0], $e[1]]]))
    | reduce ($prune | map(.[0]) | unique[]) as $s (.; if .[$s] == {} then delpaths([[$s]]) else . end)
    | . * $n' "$target" >"$tmp/merged" 2>"$tmp/err" || fail "$(head -n1 "$tmp/err")"
  "$jq" -e 'type == "object"' "$tmp/merged" >/dev/null 2>&1 || fail "invalid result"
else
  cp "$nix" "$tmp/merged" || fail "copy failed"
fi

mkdir -p "$(dirname "$target")" "$(dirname "$manifest")" || fail "cannot create directories"
# The new manifest is staged beside the old one first, so a write failure leaves both files as they were; the final
# rename is the only step after keys.json changes.
install -m 644 "$tmp/manifest" "$manifest.new" || fail "cannot write the manifest"
install -m 644 "$tmp/merged" "$target" || { rm -f "$manifest.new"; fail "cannot write keys.json"; }
if ! mv -f "$manifest.new" "$manifest"; then
  rm -f "$manifest.new"
  echo "herdr-app: keys.json was updated but $manifest was not; the next activation prunes against the old manifest and retries" >&2
fi
