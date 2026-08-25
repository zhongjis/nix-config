#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-lark-package [options]

Update the local Lark desktop package from the official download API.

Options:
  --check         fail if packages/lark.nix is not on the latest release; do not write
  --package PATH  package file to update (default: packages/lark.nix)
  --no-format     skip running alejandra after writing
  -h, --help      show this help
EOF
}

check_mode=0
format_file=1
package_path="packages/lark.nix"

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
  command -v "$1" >/dev/null 2>&1 || { echo "error: required command not found: $1" >&2; exit 1; }
}

require_cmd curl
require_cmd git
require_cmd jq
require_cmd nix
require_cmd python3

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$package_path" != /* ]]; then
  package_path="$repo_root/$package_path"
fi
[[ -f "$package_path" ]] || { echo "error: package file not found: $package_path" >&2; exit 1; }

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

api_json="$(curl -fsSL https://www.larksuite.com/api/downloads)"

read_download() {
  local key="$1"
  jq -er --arg key "$key" '
    .versions[$key]
    | select(type == "object")
    | [.version_number, .download_link]
    | @tsv
  ' <<<"$api_json"
}

IFS=$'\t' read -r x86_version_field x86_url <<<"$(read_download Linux_deb_x64)"
IFS=$'\t' read -r arm_version_field arm_url <<<"$(read_download Linux_deb_arm)"
latest_version="${x86_version_field##*@V}"
arm_version="${arm_version_field##*@V}"

if [[ ! "$latest_version" =~ ^[0-9]+(\.[0-9]+)+$ || "$arm_version" != "$latest_version" ]]; then
  echo "error: invalid or mismatched Lark Linux versions: x86=$x86_version_field arm=$arm_version_field" >&2
  exit 1
fi

validate_url() {
  local url="$1"
  local arch="$2"
  local expected_name="Lark-linux_${arch}-${latest_version}.deb"
  if [[ ! "$url" =~ ^https://[^/]+\.larksuitecdn\.com/obj/lark-version-sg/[A-Za-z0-9_-]+/${expected_name}$ ]]; then
    echo "error: unexpected Lark download URL: $url" >&2
    exit 1
  fi
}

validate_url "$x86_url" x64
validate_url "$arm_url" arm64

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Lark already up to date: $current_version"
  exit 0
fi

if [[ "$check_mode" -eq 1 ]]; then
  echo "Lark update available: $current_version -> $latest_version" >&2
  exit 1
fi

prefetch_hash() {
  nix store prefetch-file --json "$1" | jq -er '.hash | select(startswith("sha256-"))'
}

echo "Updating Lark: $current_version -> $latest_version"
echo "Prefetching x86_64 package"
x86_hash="$(prefetch_hash "$x86_url")"
echo "Prefetching aarch64 package"
arm_hash="$(prefetch_hash "$arm_url")"

python3 - "$package_path" "$latest_version" "$x86_url" "$x86_hash" "$arm_url" "$arm_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
latest_version, x86_url, x86_hash, arm_url, arm_hash = sys.argv[2:7]
x86_url = x86_url.replace(f"-{latest_version}.deb", "-${version}.deb")
arm_url = arm_url.replace(f"-{latest_version}.deb", "-${version}.deb")
text = path.read_text(encoding="utf-8")

text, count = re.subn(
    r'(^\s*version = ")[^"]+(";)',
    rf'\g<1>{latest_version}\2',
    text,
    count=1,
    flags=re.M,
)
if count != 1:
    raise SystemExit(f"error: expected to replace 1 version, replaced {count}")

for system, url, sha256 in (
    ("x86_64-linux", x86_url, x86_hash),
    ("aarch64-linux", arm_url, arm_hash),
):
    pattern = rf'({re.escape(system)} = \{{\n\s+url = ")[^"]+(";\n\s+sha256 = ")[^"]+(";)'
    replacement = rf'\g<1>{url}\2{sha256}\3'
    text, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise SystemExit(f"error: expected to replace 1 source for {system}, replaced {count}")

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
