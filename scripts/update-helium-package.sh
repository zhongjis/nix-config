#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-helium-package [options]

Update the local Helium AppImage package to the latest GitHub release.

Options:
  --check         fail if packages/helium.nix is not on the latest release; do not write
  --package PATH  package file to update (default: packages/helium.nix)
  --no-format     skip running alejandra after writing
  -h, --help      show this help

Environment:
  GITHUB_TOKEN or GH_TOKEN  optional token for GitHub API requests
EOF
}

check_mode=0
format_file=1
package_path="packages/helium.nix"

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
    --no-format)
      format_file=0
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

require_cmd curl
require_cmd jq
require_cmd nix
require_cmd python3

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$package_path" != /* ]]; then
  package_path="$repo_root/$package_path"
fi

if [[ ! -f "$package_path" ]]; then
  echo "error: package file not found: $package_path" >&2
  exit 1
fi

current_version="$(python3 - "$package_path" <<'PY'
import re
import sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'^\s*version = "([^"]+)";', text, re.M)
if not match:
    raise SystemExit("error: version not found")
print(match.group(1))
PY
)"

api_url="https://api.github.com/repos/imputnet/helium-linux/releases/latest"
curl_args=(-fsSL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")
github_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [[ -n "$github_token" ]]; then
  curl_args+=(-H "Authorization: Bearer $github_token")
fi

release_json="$(curl "${curl_args[@]}" "$api_url")"
latest_version="$(jq -r '.tag_name // empty' <<<"$release_json")"

if [[ ! "$latest_version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  echo "error: invalid latest Helium tag from GitHub API: ${latest_version:-<empty>}" >&2
  exit 1
fi

asset_url() {
  local name="$1"
  jq -er --arg name "$name" '
    [ .assets[]? | select(.name == $name) | .browser_download_url ]
    | if length == 1 then .[0] else error("expected exactly one asset named " + $name) end
  ' <<<"$release_json"
}

x86_asset="helium-${latest_version}-x86_64.AppImage"
arm_asset="helium-${latest_version}-arm64.AppImage"
x86_url="$(asset_url "$x86_asset")"
arm_url="$(asset_url "$arm_asset")"

expected_x86_url="https://github.com/imputnet/helium-linux/releases/download/${latest_version}/${x86_asset}"
expected_arm_url="https://github.com/imputnet/helium-linux/releases/download/${latest_version}/${arm_asset}"
if [[ "$x86_url" != "$expected_x86_url" || "$arm_url" != "$expected_arm_url" ]]; then
  echo "error: release asset URL pattern changed; refusing to update" >&2
  echo "expected: $expected_x86_url" >&2
  echo "got:      $x86_url" >&2
  echo "expected: $expected_arm_url" >&2
  echo "got:      $arm_url" >&2
  exit 1
fi

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Helium already up to date: $current_version"
  exit 0
fi

if [[ "$check_mode" -eq 1 ]]; then
  echo "Helium update available: $current_version -> $latest_version" >&2
  exit 1
fi

prefetch_hash() {
  local url="$1"
  local raw_hash
  raw_hash="$(nix store prefetch-file --json "$url" | jq -r '.hash')"
  if [[ "$raw_hash" == sha256-* ]]; then
    printf '%s\n' "$raw_hash"
  else
    nix hash convert --hash-algo sha256 --to sri "$raw_hash"
  fi
}

echo "Updating Helium: $current_version -> $latest_version"
echo "Prefetching $x86_asset"
x86_hash="$(prefetch_hash "$x86_url")"
echo "Prefetching $arm_asset"
arm_hash="$(prefetch_hash "$arm_url")"

python3 - "$package_path" "$latest_version" "$x86_hash" "$arm_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
latest_version, x86_hash, arm_hash = sys.argv[2:5]
text = path.read_text(encoding="utf-8")

text, version_count = re.subn(
    r'(^\s*version = ")[^"]+(";)',
    rf'\g<1>{latest_version}\2',
    text,
    count=1,
    flags=re.M,
)
if version_count != 1:
    raise SystemExit(f"error: expected to replace 1 version, replaced {version_count}")

patterns = [
    (
        "x86_64-linux",
        x86_hash,
        r'(x86_64-linux = \{\n\s+url = "[^"]+";\n\s+sha256 = ")[^"]+(")',
    ),
    (
        "aarch64-linux",
        arm_hash,
        r'(aarch64-linux = \{\n\s+url = "[^"]+";\n\s+sha256 = ")[^"]+(")',
    ),
]

for system, sha256, pattern in patterns:
    text, count = re.subn(pattern, rf'\g<1>{sha256}\2', text, count=1)
    if count != 1:
        raise SystemExit(f"error: expected to replace 1 hash for {system}, replaced {count}")

path.write_text(text, encoding="utf-8")
PY

if [[ "$format_file" -eq 1 ]]; then
  if command -v alejandra >/dev/null 2>&1; then
    alejandra "$package_path"
  else
    echo "warning: alejandra not found; skipped formatting" >&2
  fi
fi

echo "Updated $package_path"
