#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-likec4-package [options]

Update the local LikeC4 package to the latest npm release.

Options:
  --check           fail if the package is not current; do not write
  --package PATH    package file to update (default: packages/likec4.nix)
  --lock-file PATH  generated npm lock file (default: packages/likec4-package-lock.json)
  --no-format       skip running alejandra after writing
  -h, --help        show this help
EOF
}

check_mode=0
format_file=1
package_path="packages/likec4.nix"
lock_path="packages/likec4-package-lock.json"

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
require_cmd git
require_cmd jq
require_cmd nix
require_cmd npm
require_cmd prefetch-npm-deps
require_cmd python3
require_cmd tar

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
if [[ ! -f "$lock_path" ]]; then
  echo "error: lock file not found: $lock_path" >&2
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
lock_version="$(jq -r '.packages[""].version // empty' "$lock_path")"

registry_url="https://registry.npmjs.org/likec4"
registry_json="$(curl -fsSL "$registry_url")"
latest_version="$(jq -r '."dist-tags".latest // empty' <<<"$registry_json")"
if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: invalid npm latest version: ${latest_version:-<empty>}" >&2
  exit 1
fi

release_json="$(jq -c --arg version "$latest_version" '.versions[$version] // empty' <<<"$registry_json")"
package_name="$(jq -r '.name // empty' <<<"$release_json")"
tarball_url="$(jq -r '.dist.tarball // empty' <<<"$release_json")"
registry_bin="$(jq -r '.bin.likec4 // empty' <<<"$release_json")"
node_engine="$(jq -r '.engines.node // empty' <<<"$release_json")"
if [[ "$package_name" != "likec4" ]]; then
  echo "error: unexpected npm package name: ${package_name:-<empty>}" >&2
  exit 1
fi
if [[ "$tarball_url" != "https://registry.npmjs.org/likec4/-/likec4-${latest_version}.tgz" ]]; then
  echo "error: npm tarball URL pattern changed: ${tarball_url:-<empty>}" >&2
  exit 1
fi
if [[ "$registry_bin" != "bin/likec4.mjs" && "$registry_bin" != "./bin/likec4.mjs" ]]; then
  echo "error: unexpected LikeC4 executable: ${registry_bin:-<empty>}" >&2
  exit 1
fi
if [[ "$node_engine" != ">=22.22.3" ]]; then
  echo "error: unexpected Node.js requirement: ${node_engine:-<empty>}" >&2
  exit 1
fi

if [[ "$current_version" == "$latest_version" && "$lock_version" == "$latest_version" ]]; then
  echo "likec4 already up to date: $current_version"
  exit 0
fi
if [[ "$check_mode" -eq 1 ]]; then
  echo "likec4 update available: $current_version -> $latest_version" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive="$tmp_dir/likec4.tgz"
source_dir="$tmp_dir/source"
curl -fsSL "$tarball_url" -o "$archive"
mkdir "$source_dir"
tar -xzf "$archive" -C "$source_dir" --strip-components=1

published_name="$(jq -r '.name // empty' "$source_dir/package.json")"
published_version="$(jq -r '.version // empty' "$source_dir/package.json")"
published_bin="$(jq -r '.bin.likec4 // empty' "$source_dir/package.json")"
published_engine="$(jq -r '.engines.node // empty' "$source_dir/package.json")"
esbuild_version="$(jq -r '.dependencies.esbuild // empty' "$source_dir/package.json")"
playwright_version="$(jq -r '.dependencies.playwright // empty' "$source_dir/package.json")"
if [[ "$published_name" != "likec4" || "$published_version" != "$latest_version" ]]; then
  echo "error: tarball package identity does not match registry metadata" >&2
  exit 1
fi
if [[ "$published_bin" != "bin/likec4.mjs" && "$published_bin" != "./bin/likec4.mjs" ]]; then
  echo "error: tarball has unexpected LikeC4 executable: ${published_bin:-<empty>}" >&2
  exit 1
fi
if [[ "$published_engine" != ">=22.22.3" ]]; then
  echo "error: tarball has unexpected Node.js requirement: ${published_engine:-<empty>}" >&2
  exit 1
fi
if [[ -z "$esbuild_version" || -z "$playwright_version" ]]; then
  echo "error: tarball no longer declares esbuild and Playwright dependencies" >&2
  exit 1
fi
if [[ ! -f "$source_dir/bin/likec4.mjs" || ! -f "$source_dir/dist/cli/index.mjs" ]]; then
  echo "error: tarball does not contain the compiled LikeC4 CLI" >&2
  exit 1
fi

npm pkg delete devDependencies --prefix "$source_dir"
(
  cd "$source_dir"
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install \
    --package-lock-only --ignore-scripts --no-audit --no-fund
)
new_lock="$tmp_dir/likec4-package-lock.json"
cp "$source_dir/package-lock.json" "$new_lock"

prefetched_hash="$(prefetch-npm-deps "$new_lock")"
if [[ ! "$prefetched_hash" =~ ^sha256- ]]; then
  echo "error: invalid npm dependency hash: ${prefetched_hash:-<empty>}" >&2
  exit 1
fi
source_hash="$(nix store prefetch-file --json "$tarball_url" | jq -r '.hash // empty')"
if [[ ! "$source_hash" =~ ^sha256- ]]; then
  echo "error: invalid source hash: ${source_hash:-<empty>}" >&2
  exit 1
fi

new_package="$tmp_dir/likec4.nix"
python3 - "$package_path" "$new_package" "$latest_version" "$source_hash" "$prefetched_hash" <<'PY'
import re
import sys
from pathlib import Path

source, destination = map(Path, sys.argv[1:3])
version, source_hash, npm_hash = sys.argv[3:6]
text = source.read_text(encoding="utf-8")
replacements = [
    (r'(^\s*version = ")[^"]+(";)', rf'\g<1>{version}\2', "version"),
    (r'(^\s*hash = ")[^"]+(";)', rf'\g<1>{source_hash}\2', "source hash"),
    (r'(^\s*npmDepsHash = )[^;]+(;)', rf'\g<1>"{npm_hash}"\2', "npm dependency hash"),
]
for pattern, replacement, name in replacements:
    text, count = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if count != 1:
        raise SystemExit(f"error: expected to replace 1 {name}, replaced {count}")
destination.write_text(text, encoding="utf-8")
PY

if [[ "$format_file" -eq 1 ]]; then
  if command -v alejandra >/dev/null 2>&1; then
    alejandra "$new_package"
  else
    echo "warning: alejandra not found; skipped formatting" >&2
  fi
fi

staged_package="$(mktemp "$(dirname "$package_path")/.likec4.nix.XXXXXX")"
staged_lock="$(mktemp "$(dirname "$lock_path")/.likec4-lock.XXXXXX")"
cp "$new_package" "$staged_package"
cp "$new_lock" "$staged_lock"
mv "$staged_lock" "$lock_path"
mv "$staged_package" "$package_path"

echo "Updated likec4: $current_version -> $latest_version"
echo "Updated $package_path"
echo "Updated $lock_path"
