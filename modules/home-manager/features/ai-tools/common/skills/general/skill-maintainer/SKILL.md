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

> Where would you like to install this skill?
>
> 1. **This Nix config** — System-wide via Home Manager (persists across rebuilds)
>    - `modules/home-manager/features/ai-tools/common/skills/general/` (all systems)
>    - `modules/home-manager/features/ai-tools/common/skills/work/` (work profile)
>    - `modules/home-manager/features/ai-tools/common/skills/personal/` (personal profile)
> 2. **Project-level** — `.agents/skills/` (this repo only)
> 3. **Specific coding tool** — directly into a tool's config directory

### If Generic Project

> Where would you like to install this skill?
>
> 1. **Project-level** — `.agents/skills/` (this repo only)
> 2. **Specific coding tool** — directly into a tool's config directory

### Tool-Specific Paths

When the user chooses "specific coding tool", ask which tool:

| Tool | Skill Path |
|------|-----------|
| OpenCode | `~/.config/opencode/skills/` |
| Claude Code | `~/.claude/skills/` |
| Factory.ai | `~/.factory/skills/` |

If the user's tool is not listed, ask them for the path.

## Upstream Tracking Convention

Skills from external sources have an `upstream` field in their YAML frontmatter:

```yaml
---
name: skill-name
description: "..."
upstream: "https://github.com/org/repo/tree/main/skills/skill-name"
---
```

- **`upstream` present** → Single canonical sync source. Sourced from an external repository. Can be updated from this URL. Must be a singular string — never a list.
- **`upstream` absent** → Locally created. Do NOT attempt to update from external sources.
- **`adaptedFrom` present** → Informational lineage only. Lists prior or merged sources. Do NOT treat these URLs as additional upstreams during sync or update operations. Example:
  ```yaml
  adaptedFrom:
    - "https://github.com/previous-org/repo/tree/main/skills/skill-name"
  ```

### Identifying Skills by Provenance

Adapt the search path based on the detected context:

```bash
# In a Nix config repo — search Nix-managed skills
grep -rl '^upstream:' modules/home-manager/features/ai-tools/common/skills/ --include="SKILL.md"

# In any project — search project-level skills
grep -rl '^upstream:' .agents/skills/ --include="SKILL.md"

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

## Clone-to-/tmp Workflow

**All skill fetching uses `git clone` into an isolated temp dir under `/tmp`.** This preserves exact upstream content, avoids shared `/tmp/{repo}` collisions, and keeps cleanup scoped to current run.

### Step 1: Clone

> Prefer one shell/session for clone → compare/copy → cleanup so the trap always runs.

```bash
WANT_REMOTE="https://github.com/{owner}/{repo}.git"
CLONE_DIR=$(mktemp -d "/tmp/skill-maintainer-{repo}.XXXXXX")
cleanup() { rm -rf "$CLONE_DIR"; }
trap cleanup EXIT

git clone --depth 1 -b {branch} "$WANT_REMOTE" "$CLONE_DIR"
```

If you must switch shells mid-workflow, remove the temp dir you created when finished. Do not delete a shared `/tmp/{repo}` path by default.

### Step 2: Locate the Skill

```bash
# Verify the skill exists at the parsed path
ls "$CLONE_DIR/{path/to/skill}/"
```

The skill directory should contain at minimum a `SKILL.md`. It may also contain supporting files (scripts/, references/, assets/, etc.).

### Step 3: Copy to Target

```bash
# Copy the entire skill directory to the user's chosen install target
cp -r "$CLONE_DIR/{path/to/skill}" {target-location}/{skill-name}
```

Where `{target-location}` is the path chosen by the user during Install Target Selection.

### Step 4: Clean Up

Cleanup should happen automatically via the `trap` above. Only run a manual `rm -rf "$CLONE_DIR"` as a fallback when the workflow could not stay in one shell/session.

## Adding New Skills from Upstream

When adding a skill from an external source for the first time:

1. **Detect context** and **ask the user** for the install target (see Context Detection and Install Target Selection above)
2. **Parse the URL** to extract clone URL, branch, and skill path (see URL Parsing above)
3. **Clone and copy** using the Clone-to-/tmp Workflow above
4. **Fix the frontmatter** in the copied SKILL.md:
   - Add the `upstream` field set to the original GitHub tree URL (singular string)
   - If this skill adapts or merges content from a prior source, add `adaptedFrom` as a YAML list of informational lineage URLs — these are NOT synced automatically
   - Remove any `license`, `source`, or other non-standard tracking fields — `upstream` is the canonical provenance field
   - Verify `name` and `description` are present and accurate
5. **Genericize** all vendor-specific references (see Genericize section below)
6. **Verify** — if in a Nix config repo, run `nix flake check --no-build`

## Update Workflow

### Step 1: Identify Skills to Update

Search for skills with `upstream` fields in the relevant location:

```bash
# Adapt the search path to context (Nix-managed, project-level, or tool-specific)
grep -r '^upstream:' {skills-directory} --include="SKILL.md"
```

### Step 2: Clone and Compare

For each skill (or batch of skills from the same repo):

1. **Parse the `upstream` URL** to extract clone URL, branch, and skill path
2. **Clone the repo** to an isolated temp dir under `/tmp` using the Clone-to-/tmp Workflow
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

Cleanup should already be handled by the temp-dir `trap` from the clone step; only remove `"$CLONE_DIR"` manually if you had to continue in a different shell/session.

## Genericize (MANDATORY)

**All skills must be vendor-neutral.** Apply these replacements to any new or updated content:

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

## Handling Heavily Vendor-Specific Content

Some upstream skills or sections may be deeply tied to a specific vendor's ecosystem (e.g., eval frameworks requiring vendor-specific CLI tools, cloud VM instructions). In these cases:

- **Skip sections** that cannot be meaningfully genericized
- **Adapt concepts** — take the useful idea and rewrite it generically
- **Document decisions** — note in the PR/commit why certain content was skipped

Example: An upstream eval framework requiring `claude -p` to spawn test runs should be skipped entirely, but the concept of "test your skill on real tasks and iterate" can be captured in generic terms.

## When NOT to Use This Skill

- Modifying **local-only skills** (no `upstream` field) — those are custom and not synced from anywhere
- Creating **brand new skills from scratch** — use the `skill-creator` skill instead
- **Discovering** what skills exist in the ecosystem — use the `find-skills` skill instead
