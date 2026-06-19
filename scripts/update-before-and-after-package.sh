#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-before-and-after-package [options]

Update the local before-and-after package from npm and vendor the upstream skill.

Options:
  --check           fail if package or skill is not up to date; do not write
  --package PATH    package file to update (default: packages/before-and-after.nix)
  --skill-dir PATH  vendored skill dir to update
                   (default: modules/home-manager/features/ai-tools/common/skills/personal/before-and-after)
  --no-format       skip running alejandra after writing
  -h, --help        show this help

Environment:
  GITHUB_TOKEN or GH_TOKEN  optional token for GitHub API requests
EOF
}

check_mode=0
format_file=1
package_path="packages/before-and-after.nix"
skill_dir="modules/home-manager/features/ai-tools/common/skills/personal/before-and-after"

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
    --skill-dir)
      [[ $# -ge 2 ]] || { echo "error: --skill-dir requires PATH" >&2; exit 2; }
      skill_dir="$2"
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
require_cmd tar

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$package_path" != /* ]]; then
  package_path="$repo_root/$package_path"
fi
if [[ "$skill_dir" != /* ]]; then
  skill_dir="$repo_root/$skill_dir"
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
git_head = re.search(r'^\s*gitHead = "([0-9a-f]{40})";', text, re.M)
if not version:
    raise SystemExit("error: version not found")
if not git_head:
    raise SystemExit("error: gitHead not found")
print(version.group(1))
print(git_head.group(1))
PY
)"
current_version="$(sed -n '1p' <<<"$current_values")"
current_git_head="$(sed -n '2p' <<<"$current_values")"

marker_path="$skill_dir/UPSTREAM_COMMIT"
current_skill_commit=""
if [[ -f "$marker_path" ]]; then
  current_skill_commit="$(<"$marker_path")"
fi

npm_registry_url="https://registry.npmjs.org/@vercel%2fbefore-and-after"
npm_json="$(curl -fsSL "$npm_registry_url")"
latest_version="$(jq -r '."dist-tags".latest // empty' <<<"$npm_json")"
if [[ ! "$latest_version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  echo "error: invalid npm latest version: ${latest_version:-<empty>}" >&2
  exit 1
fi

package_json="$(jq -c --arg version "$latest_version" '.versions[$version] // empty' <<<"$npm_json")"
package_name="$(jq -r '.name // empty' <<<"$package_json")"
latest_git_head="$(jq -r '.gitHead // empty' <<<"$package_json")"
tarball_url="$(jq -r '.dist.tarball // empty' <<<"$package_json")"
license="$(jq -r '.license // empty' <<<"$package_json")"

if [[ "$package_name" != "@vercel/before-and-after" ]]; then
  echo "error: unexpected npm package name: ${package_name:-<empty>}" >&2
  exit 1
fi
if [[ ! "$latest_git_head" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: invalid npm gitHead: ${latest_git_head:-<empty>}" >&2
  exit 1
fi
if [[ "$tarball_url" != "https://registry.npmjs.org/@vercel/before-and-after/-/before-and-after-${latest_version}.tgz" ]]; then
  echo "error: npm tarball URL pattern changed; refusing to update" >&2
  echo "got: $tarball_url" >&2
  exit 1
fi
if [[ "$license" != "PolyForm-Shield-1.0.0" ]]; then
  echo "error: upstream license changed: ${license:-<empty>}" >&2
  exit 1
fi

github_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
github_curl_args=(-fsSL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")
if [[ -n "$github_token" ]]; then
  github_curl_args+=(-H "Authorization: Bearer $github_token")
fi

skill_commits_url="https://api.github.com/repos/vercel-labs/before-and-after/commits?path=skill&sha=main&per_page=1"
skill_commit_json="$(curl "${github_curl_args[@]}" "$skill_commits_url")"
latest_skill_commit="$(jq -r '.[0].sha // empty' <<<"$skill_commit_json")"
if [[ ! "$latest_skill_commit" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: invalid latest skill commit: ${latest_skill_commit:-<empty>}" >&2
  exit 1
fi

package_changed=0
skill_changed=0
if [[ "$current_version" != "$latest_version" || "$current_git_head" != "$latest_git_head" ]]; then
  package_changed=1
fi
if [[ "$current_skill_commit" != "$latest_skill_commit" ]]; then
  skill_changed=1
fi

if [[ "$package_changed" -eq 0 && "$skill_changed" -eq 0 ]]; then
  echo "before-and-after already up to date: package $current_version ($current_git_head), skill $current_skill_commit"
  exit 0
fi

if [[ "$check_mode" -eq 1 ]]; then
  if [[ "$package_changed" -eq 1 ]]; then
    echo "before-and-after package update available: $current_version ($current_git_head) -> $latest_version ($latest_git_head)" >&2
  fi
  if [[ "$skill_changed" -eq 1 ]]; then
    echo "before-and-after skill update available: ${current_skill_commit:-<none>} -> $latest_skill_commit" >&2
  fi
  exit 1
fi

if [[ "$package_changed" -eq 1 ]]; then
  echo "Updating before-and-after package: $current_version -> $latest_version"
  raw_hash="$(nix store prefetch-file --json "$tarball_url" | jq -r '.hash')"
  if [[ "$raw_hash" == sha256-* ]]; then
    source_hash="$raw_hash"
  else
    source_hash="$(nix hash convert --hash-algo sha256 --to sri "$raw_hash")"
  fi

  python3 - "$package_path" "$latest_version" "$latest_git_head" "$source_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
latest_version, latest_git_head, source_hash = sys.argv[2:5]
text = path.read_text(encoding="utf-8")

replacements = [
    (r'(^\s*version = ")[^"]+(";)', rf'\g<1>{latest_version}\2', "version"),
    (r'(^\s*gitHead = ")[0-9a-f]{{40}}(";)', rf'\g<1>{latest_git_head}\2', "gitHead"),
    (r'(^\s*hash = ")[^"]+(";)', rf'\g<1>{source_hash}\2', "hash"),
]
for pattern, replacement, name in replacements:
    text, count = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if count != 1:
        raise SystemExit(f"error: expected to replace 1 {name}, replaced {count}")

path.write_text(text, encoding="utf-8")
PY
fi

if [[ "$skill_changed" -eq 1 ]]; then
  echo "Updating before-and-after skill: ${current_skill_commit:-<none>} -> $latest_skill_commit"
  tmp_dir="$(mktemp -d)"
  cleanup() {
    rm -rf "$tmp_dir"
  }
  trap cleanup EXIT

  archive_path="$tmp_dir/before-and-after.tgz"
  curl "${github_curl_args[@]}" -L \
    "https://api.github.com/repos/vercel-labs/before-and-after/tarball/$latest_skill_commit" \
    -o "$archive_path"
  top_dir="$(tar -tzf "$archive_path" | sed -n '1s,/.*,,p')"
  if [[ -z "$top_dir" ]]; then
    echo "error: could not determine GitHub tarball top directory" >&2
    exit 1
  fi
  tar -xzf "$archive_path" -C "$tmp_dir"

  upstream_skill_dir="$tmp_dir/$top_dir/skill"
  if [[ ! -f "$upstream_skill_dir/SKILL.md" ]]; then
    echo "error: upstream skill missing SKILL.md" >&2
    exit 1
  fi

  rm -rf "$skill_dir"
  mkdir -p "$(dirname "$skill_dir")"
  cp -R "$upstream_skill_dir" "$skill_dir"
  printf '%s\n' "$latest_skill_commit" > "$marker_path"

  python3 - "$skill_dir/SKILL.md" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
upstream = 'upstream: "https://github.com/vercel-labs/before-and-after/tree/main/skill"'
text = path.read_text(encoding="utf-8")
if re.search(r'^upstream: ', text, flags=re.M):
    text = re.sub(r'^upstream: .*$', upstream, text, count=1, flags=re.M)
else:
    text = re.sub(r'^(description: .*)$', rf'\1\n{upstream}', text, count=1, flags=re.M)
path.write_text(text, encoding="utf-8")
PY
fi

if [[ "$format_file" -eq 1 ]]; then
  if command -v alejandra >/dev/null 2>&1; then
    alejandra "$package_path"
  else
    echo "warning: alejandra not found; skipped formatting" >&2
  fi
fi

echo "Updated before-and-after package and skill metadata"
