#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-opencode-morph-fast-apply-package [options]

Update the local opencode-morph-fast-apply package to the latest GitHub release.

Options:
  --check          fail if package is not on the latest release; do not write
  --package PATH   package file to update (default: packages/opencode-morph-fast-apply.nix)
  --lock-file PATH generated bun2nix lock file (default: packages/opencode-morph-fast-apply-bun-lock.nix)
  --no-format      skip running alejandra after writing
  -h, --help       show this help

Environment:
  GITHUB_TOKEN or GH_TOKEN  optional token for GitHub API requests
EOF
}

check_mode=0
format_files=1
package_path="packages/opencode-morph-fast-apply.nix"
lock_path="packages/opencode-morph-fast-apply-bun-lock.nix"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check_mode=1
      shift
      ;;
    --package)
      [[ $# -ge 2 ]] || { echo "error: --package requires PATH" >&2; exit 2; }
      package_path="$2"
      shift 2
      ;;
    --lock-file)
      [[ $# -ge 2 ]] || { echo "error: --lock-file requires PATH" >&2; exit 2; }
      lock_path="$2"
      shift 2
      ;;
    --no-format)
      format_files=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd bun2nix
require_cmd curl
require_cmd git
require_cmd jq
require_cmd nix-prefetch-github
require_cmd python3

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$package_path" != /* ]]; then
  package_path="$repo_root/$package_path"
fi
if [[ "$lock_path" != /* ]]; then
  lock_path="$repo_root/$lock_path"
fi

if [[ ! -f "$package_path" ]]; then
  echo "error: package file not found: $package_path" >&2
  exit 1
fi

current_values="$(python3 - "$package_path" <<'PY'
import re
import sys
text = open(sys.argv[1], encoding="utf-8").read()
version = re.search(r'^\s*version = "([^"]+)";', text, re.M)
rev = re.search(r'^\s*rev = "([0-9a-f]{40})";', text, re.M)
if not version:
    raise SystemExit("error: version not found")
if not rev:
    raise SystemExit("error: rev not found")
print(version.group(1))
print(rev.group(1))
PY
)"
current_version="$(sed -n '1p' <<<"$current_values")"
current_rev="$(sed -n '2p' <<<"$current_values")"

api_url="https://api.github.com/repos/JRedeker/opencode-morph-fast-apply/releases/latest"
curl_args=(-fsSL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")
github_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [[ -n "$github_token" ]]; then
  curl_args+=(-H "Authorization: Bearer $github_token")
fi

release_json="$(curl "${curl_args[@]}" "$api_url")"
tag="$(jq -r '.tag_name // empty' <<<"$release_json")"
draft="$(jq -r 'if has("draft") then .draft else true end' <<<"$release_json")"
prerelease="$(jq -r 'if has("prerelease") then .prerelease else true end' <<<"$release_json")"
target_commitish="$(jq -r '.target_commitish // empty' <<<"$release_json")"

if [[ ! "$tag" =~ ^v[0-9]+(\.[0-9]+)+$ ]]; then
  echo "error: invalid latest opencode-morph-fast-apply tag: ${tag:-<empty>}" >&2
  exit 1
fi
if [[ "$draft" != "false" || "$prerelease" != "false" ]]; then
  echo "error: latest release is draft or prerelease: $tag" >&2
  exit 1
fi
if [[ "$target_commitish" != "trunk" ]]; then
  echo "error: latest release target_commitish changed: ${target_commitish:-<empty>}" >&2
  exit 1
fi

latest_version="${tag#v}"
repo_url="https://github.com/JRedeker/opencode-morph-fast-apply.git"
latest_rev="$(git ls-remote --tags "$repo_url" "refs/tags/$tag^{}" | awk '{print $1}')"
if [[ -z "$latest_rev" ]]; then
  latest_rev="$(git ls-remote --tags "$repo_url" "refs/tags/$tag" | awk '{print $1}')"
fi
if [[ ! "$latest_rev" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: could not resolve tag to commit SHA: $tag" >&2
  exit 1
fi

if [[ "$current_version" == "$latest_version" && "$current_rev" == "$latest_rev" ]]; then
  echo "opencode-morph-fast-apply already up to date: $current_version ($current_rev)"
  exit 0
fi

if [[ "$check_mode" -eq 1 ]]; then
  echo "opencode-morph-fast-apply update available: $current_version ($current_rev) -> $latest_version ($latest_rev)" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

source_dir="$tmp_dir/source"
git clone --depth 1 --branch "$tag" "$repo_url" "$source_dir" >/dev/null 2>&1

package_json_version="$(jq -r '.version // empty' "$source_dir/package.json")"
if [[ "$package_json_version" != "$latest_version" ]]; then
  echo "error: package.json version $package_json_version does not match release $tag" >&2
  exit 1
fi
if [[ ! -f "$source_dir/bun.lock" ]]; then
  echo "error: upstream release $tag does not contain bun.lock" >&2
  exit 1
fi

prefetch_json="$(nix-prefetch-github JRedeker opencode-morph-fast-apply --rev "$latest_rev")"
source_hash="$(jq -r '.hash // empty' <<<"$prefetch_json")"
if [[ ! "$source_hash" =~ ^sha256- ]]; then
  echo "error: invalid source hash from nix-prefetch-github: ${source_hash:-<empty>}" >&2
  exit 1
fi

echo "Updating opencode-morph-fast-apply: $current_version -> $latest_version"
python3 - "$package_path" "$latest_version" "$latest_rev" "$source_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
latest_version, latest_rev, source_hash = sys.argv[2:5]
text = path.read_text(encoding="utf-8")

replacements = [
    (r'(^\s*version = ")[^"]+(";)', rf'\g<1>{latest_version}\2', "version"),
    (r'(^\s*rev = ")[0-9a-f]{40}(";)', rf'\g<1>{latest_rev}\2', "rev"),
    (r'(^\s*hash = ")[^"]+(";)', rf'\g<1>{source_hash}\2', "hash"),
]

for pattern, replacement, name in replacements:
    text, count = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if count != 1:
        raise SystemExit(f"error: expected to replace 1 {name}, replaced {count}")

path.write_text(text, encoding="utf-8")
PY

bun2nix -l "$source_dir/bun.lock" -o "$lock_path"

if [[ "$format_files" -eq 1 ]]; then
  if command -v alejandra >/dev/null 2>&1; then
    alejandra "$package_path" "$lock_path"
  else
    echo "warning: alejandra not found; skipped formatting" >&2
  fi
fi

echo "Updated $package_path"
echo "Updated $lock_path"
