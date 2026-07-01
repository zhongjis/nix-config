---
name: skill-maintainer
description: "Maintain AI agent skills — add from upstream repositories, update from upstream sources, check for updates, sync with upstream, and manage skill provenance. Works in any project. Triggers on 'add skill from [URL]', 'install skill', 'update skills', 'sync skills from upstream', 'check for skill updates', 'which skills are from upstream?', 'compare skill with upstream', or 'update the anthropic skills'."
---

# Skill Maintainer

Maintain AI agent skills — add new skills from external sources, update existing skills from upstream, and manage skill provenance tracking. Works in any project context.

## Context Detection

Before performing any operation, detect the environment:

```bash
# Check if this is a Nix config repo with Home Manager skill infrastructure
if [ -f "flake.nix" ] && [ -d "modules/home-manager/features/ai-tools" ]; then
  echo "nix-config-repo"
else
  echo "generic-project"
fi
```

- **Nix config repo detected** → Offer Nix-managed skill paths as an install target
- **Generic project** → Offer project-level and tool-specific paths

## Install Target Selection

**Always ask the user where to install.** Present applicable options based on context:

### If Nix Config Repo Detected

Where would you like to install this skill?

1. **This Nix config** — System-wide via Home Manager (persists across rebuilds)
   - `modules/home-manager/features/ai-tools/common/skills/general/` (all systems)
   - `modules/home-manager/features/ai-tools/common/skills/work/` (work profile)
   - `modules/home-manager/features/ai-tools/common/skills/personal/` (personal profile)
2. **Project-level** — `.agents/skills/` (this repo only, managed by `npx skills`)
3. **Specific coding tool** — directly into a tool's config directory

### If Generic Project

Where would you like to install this skill?

1. **Project-level** — `.agents/skills/` (this repo only, managed by `npx skills`)
2. **Specific coding tool** — directly into a tool's config directory

### Project-Level Installs

When the user chooses **Project-level** (`.agents/skills/`), always install with the `skills` CLI from the project root:

```bash
npx skills add <source> -y
```

Use the original source URL, Git repo, registry name, or local path as `<source>`. Do not manually clone, copy, rewrite, genericize, add `upstream`, or adapt the skill for project-level installs. The point of this target is to let `npx skills` own the lifecycle through its project metadata, lockfile, update, remove, and list commands.

If the user has not already confirmed the install target or source, ask before using `-y`. Once confirmed, prefer the non-interactive command above.

Verify project-level installs with:

```bash
test -d .agents/skills/<skill-name>
npx skills list
```

### Tool-Specific Paths

When the user chooses "specific coding tool", ask which tool:

| Tool | Skill Path |
|------|-----------|
| OpenCode | `~/.config/opencode/skills/` |
| Claude Code | `~/.claude/skills/` |
| Factory.ai | `~/.factory/skills/` |

If the user's tool is not listed, ask them for the path.

## Upstream Tracking Convention

Manual-managed skills from external sources have an `upstream` field in their YAML frontmatter:

```yaml
---
name: skill-name
description: "..."
upstream: "https://github.com/org/repo/tree/main/skills/skill-name"
---
```

- **Manual-managed `upstream` present** → Single canonical sync source. Sourced from an external repository. Can be updated from this URL. Must be a singular string — never a list.
- **Manual-managed `upstream` absent** → Locally created. Do NOT attempt to update from external sources.
- **Project-level CLI-managed skills** → Do not add or depend on `upstream` frontmatter. Use `npx skills` lifecycle commands and project metadata instead.
- **`adaptedFrom` present** → Informational lineage only. Lists prior or merged sources. Do NOT treat these URLs as additional upstreams during sync or update operations. Example:
  ```yaml
  adaptedFrom:
    - "https://github.com/previous-org/repo/tree/main/skills/skill-name"
  ```

### Identifying Manual-Managed Skills by Provenance

Adapt the search path based on the detected manual-managed context. Do not use `upstream` searches to manage project-level CLI installs in `.agents/skills/`; use `npx skills list` instead.

```bash
# In a Nix config repo — search Nix-managed skills
grep -rl '^upstream:' modules/home-manager/features/ai-tools/common/skills/ --include="SKILL.md"

# In a tool-specific directory
grep -rl '^upstream:' ~/.config/opencode/skills/ --include="SKILL.md"
```

## URL Parsing

GitHub URLs follow this pattern:

```
https://github.com/{owner}/{repo}/tree/{branch}/{path/to/skill}
```

**Skills do NOT always live at `root/skills/`.** The path within the repo can be anything. Parse the URL to extract all components:

| Component | How to Extract | Example |
|-----------|----------------|---------|
| **Clone URL** | `https://github.com/{owner}/{repo}.git` | `https://github.com/anthropics/skills.git` |
| **Branch** | The segment after `/tree/` before the path | `main` |
| **Skill path** | Everything after `/tree/{branch}/` | `skills/mcp-builder` |
| **Skill name** | Last segment of the path (directory name) | `mcp-builder` |

### Examples

| Upstream URL | Clone URL | Branch | Skill Path |
|-------------|-----------|--------|------------|
| `https://github.com/anthropics/skills/tree/main/skills/mcp-builder` | `https://github.com/anthropics/skills.git` | `main` | `skills/mcp-builder` |
| `https://github.com/org/repo/tree/main/some/deep/path/skill-name` | `https://github.com/org/repo.git` | `main` | `some/deep/path/skill-name` |
| `https://github.com/org/repo/tree/develop/custom-skills/my-skill` | `https://github.com/org/repo.git` | `develop` | `custom-skills/my-skill` |
| `https://github.com/v1-io/v1tamins/tree/main/skills/git-master` | `https://github.com/v1-io/v1tamins.git` | `main` | `skills/git-master` |

### Parsing Tip

When the branch name is ambiguous (e.g., could contain `/`), clone with the default branch first. If the skill path doesn't exist in the clone, re-clone with `-b {branch-guess}` using longer segments.

## Reusable /tmp Repo Workflow

**This workflow applies only to manual-managed installs:** Nix-managed Home Manager paths and tool-specific directories. It does not apply to project-level `.agents/skills/` installs. For project-level installs, use `npx skills add <source> -y` from the project root instead.

All manual skill fetching uses a repo-specific temp clone under `/tmp`, not a fresh delete-and-reclone cycle each time. Reuse the existing path when it already points at the wanted remote. Only remove the path when it exists but is not the repo you need.

### Step 1: Prepare Repo Cache

> Reuse one repo-specific path per upstream repo, for example `/tmp/skill-maintainer-{owner}-{repo}`.

```bash
WANT_REMOTE="https://github.com/{owner}/{repo}.git"
CLONE_DIR="/tmp/skill-maintainer-{owner}-{repo}"

if [ -e "$CLONE_DIR" ]; then
  HAVE_REMOTE=$(git -C "$CLONE_DIR" remote get-url origin 2>/dev/null || true)

  if [ -n "$HAVE_REMOTE" ] && [ "$HAVE_REMOTE" = "$WANT_REMOTE" ]; then
    git -C "$CLONE_DIR" fetch --depth 1 origin "{branch}"
    git -C "$CLONE_DIR" checkout -B "{branch}" "origin/{branch}"
  else
    rm -rf -- "$CLONE_DIR"
    git clone --depth 1 -b "{branch}" "$WANT_REMOTE" "$CLONE_DIR"
  fi
else
  git clone --depth 1 -b "{branch}" "$WANT_REMOTE" "$CLONE_DIR"
fi
```

Before removing anything, confirm the path exists and confirm the remote does **not** match. Remove only the exact repo cache dir you checked. Never delete a shared or guessed `/tmp/{repo}` path.

### Step 2: Locate the Skill

```bash
# Verify the skill exists at the parsed path
ls "$CLONE_DIR/{path/to/skill}/"
```

The skill directory should contain at minimum a `SKILL.md`. It may also contain supporting files (scripts/, references/, assets/, etc.).

### Step 3: Copy to Manual Target

```bash
# Copy the entire skill directory to the user's chosen manual install target
cp -r "$CLONE_DIR/{path/to/skill}" {target-location}/{skill-name}
```

Where `{target-location}` is the Nix-managed or tool-specific path chosen by the user. Never use this copy step for project-level `.agents/skills/` installs.

### Step 4: Clean Up

Do **not** auto-delete a matching repo cache at the end of the run. Keep it for reuse. Only manually remove `"$CLONE_DIR"` when the path exists and you confirmed it is the wrong remote, is not a git repo, or the user explicitly asked to purge it.

## Adding New Skills from Upstream

When adding a skill from an external source for the first time:

1. **Detect context** and **ask the user** for the install target (see Context Detection and Install Target Selection above)
2. **If the target is Project-level** (`.agents/skills/`):
   - Run `npx skills add <source> -y` from the project root, using the original user-provided source URL, Git repo, registry name, or local path
   - Do not parse the URL yourself unless needed to identify `<skill-name>` for verification
   - Do not manually clone, copy, rewrite, genericize, add `upstream`, or adapt the skill
   - Verify with `test -d .agents/skills/<skill-name>` and `npx skills list`
3. **If the target is Nix-managed or tool-specific**:
   - **Parse the URL** to extract clone URL, branch, and skill path (see URL Parsing above)
   - **Prepare the repo cache and copy** using the Reusable /tmp Repo Workflow above
   - **Fix the frontmatter** in the copied SKILL.md:
     - Add the `upstream` field set to the original GitHub tree URL (singular string)
     - If this skill adapts or merges content from a prior source, add `adaptedFrom` as a YAML list of informational lineage URLs — these are NOT synced automatically
     - Remove any `license`, `source`, or other non-standard tracking fields — `upstream` is the canonical provenance field
     - Verify `name` and `description` are present and accurate
   - **Genericize** all vendor-specific references (see Genericize section below)
   - **Verify** — if in a Nix config repo, run `nix flake check --no-build`

## Update Workflow

Project-level `.agents/skills/` installs are managed by `npx skills`. Use CLI lifecycle commands for them:

```bash
npx skills list
npx skills update -y
npx skills remove <skill-name>
```

The manual update workflow below applies only to Nix-managed Home Manager paths and tool-specific directories.

### Step 1: Identify Skills to Update

Search for skills with `upstream` fields in the relevant manual-managed location:

```bash
# Adapt the search path to context (Nix-managed or tool-specific)
grep -r '^upstream:' {skills-directory} --include="SKILL.md"
```

### Step 2: Clone and Compare

For each skill (or batch of skills from the same repo):

1. **Parse the `upstream` URL** to extract clone URL, branch, and skill path
2. **Prepare or refresh the repo cache** under `/tmp` using the Reusable /tmp Repo Workflow
3. **Compare** the upstream version with the local version:

```bash
diff "$CLONE_DIR/{path/to/skill}/SKILL.md" {local-skill-dir}/SKILL.md
```

Also check for new or removed supporting files:

```bash
diff -rq "$CLONE_DIR/{path/to/skill}/" {local-skill-dir}/
```

### Step 3: Categorize Changes

For each skill, categorize:

- ✅ **Up to date** — No meaningful content changes
- ⚠️ **Needs update** — New content, fixes, or improvements available
- 🔍 **Needs review** — Changes exist but may be heavily vendor-specific

### Step 4: Apply Updates

For skills that need updating:

1. **Copy updated files** from the clone, overwriting the local versions
2. **Restore local customizations** — re-apply the `upstream` frontmatter field and any local genericizations that the copy overwrote
3. **Genericize** any new vendor-specific content (see below)

For surgical updates where only specific sections changed, prefer using `edit` to apply targeted changes from the diff rather than overwriting the entire file. This preserves local customizations without needing to re-apply them.

### Step 5: Verify

If in a Nix config repo, verify the flake:

```bash
nix flake check --no-build
```

Keep the matching temp repo cache for future runs. Only remove `"$CLONE_DIR"` manually when the path exists and you confirmed it points at the wrong remote, is not a usable git repo, or needs an explicit purge.

## Genericize (Manual-Managed Installs)

For manual-managed installs, all skills must be vendor-neutral. Apply these replacements to any new or updated content:

| Replace | With |
|---------|------|
| "Claude", "Claude Code" | "AI Agent" or "the model" |
| "Anthropic" (as branding) | "default branding" or remove |
| ".claude/skills/" | ".opencode/skills/" |
| "claude.ai" | remove or make generic |
| "Cowork", "Claude.ai's VM" | remove section entirely |
| Vendor-specific eval tooling (e.g., `claude -p`) | remove or genericize |

**Exceptions:**

- Filesystem paths like `~/.config/claude/` may remain when they are actual config paths
- Code examples showing XML/API responses may contain vendor names as data values
- The `upstream` URL itself references vendor repos — this is expected

Do not genericize or adapt project-level `.agents/skills/` installs. Those are CLI-managed by `npx skills`, and preserving the installed artifact keeps the CLI lifecycle predictable.

## Handling Heavily Vendor-Specific Content

Some upstream skills or sections may be deeply tied to a specific vendor's ecosystem (e.g., eval frameworks requiring vendor-specific CLI tools, cloud VM instructions). In manual-managed installs:

- **Skip sections** that cannot be meaningfully genericized
- **Adapt concepts** — take the useful idea and rewrite it generically
- **Document decisions** — note in the PR/commit why certain content was skipped

## When NOT to Use This Skill

- Modifying **manual-managed local-only skills** (no `upstream` field) — those are custom and not synced from anywhere
- Creating **brand new skills from scratch** — use the `skill-creator` skill instead
- **Discovering** what skills exist in the ecosystem — use the `find-skills` skill instead
