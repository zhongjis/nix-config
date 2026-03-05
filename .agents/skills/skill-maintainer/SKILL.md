---
name: skill-maintainer
description: "Maintain AI agent skills in this Nix config repository. Use when the user wants to add new skills from external repositories, update skills from upstream sources, check which skills need updates, sync skills with their upstream, or manage skill provenance tracking. Triggers on requests like 'add skill from [URL]', 'update skills', 'sync skills from upstream', 'check for skill updates', 'which skills are from upstream?', or 'update the anthropic skills'."
---

# Skill Maintainer

Maintain AI agent skills installed in this nix-config repository via Home Manager. Handles adding new skills from external sources, updating existing skills from upstream, and managing skill provenance.

## Skill Locations

| Location | Path | Purpose |
|----------|------|---------|
| General (shared) | `modules/home-manager/features/ai-tools/common/skills/general/` | Skills installed on all systems |
| Work | `modules/home-manager/features/ai-tools/common/skills/work/` | Work-specific skills |
| Personal | `modules/home-manager/features/ai-tools/common/skills/personal/` | Personal skills |
| Project-specific | `.agents/skills/` | Skills for this repo only (not installed system-wide) |

## Upstream Tracking Convention

Skills from external sources have an `upstream` field in their YAML frontmatter:

```yaml
---
name: skill-name
description: "..."
upstream: "https://github.com/org/repo/tree/main/skills/skill-name"
---
```

- **`upstream` present** → Sourced from an external repository. Can be updated from the URL.
- **`upstream` absent** → Locally created. Do NOT attempt to update from external sources.

### Identifying Skills by Provenance

```bash
# Find all upstream-sourced skills
grep -rl '^upstream:' modules/home-manager/features/ai-tools/common/skills/

# Find local-only skills (no upstream field)
for d in modules/home-manager/features/ai-tools/common/skills/general/*/; do
  skill=$(basename "$d")
  file="$d/SKILL.md"
  [ ! -f "$file" ] && file="$d/*/SKILL.md"
  if ! grep -q '^upstream:' $file 2>/dev/null; then
    echo "$skill (local)"
  fi
done
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

**All skill fetching uses `git clone` to `/tmp`.** This ensures exact content fidelity and avoids token-expensive file writes.

### Step 1: Clone

```bash
# Clean up any previous clone
rm -rf /tmp/{repo}

# Shallow clone the specific branch
git clone --depth 1 -b {branch} https://github.com/{owner}/{repo}.git /tmp/{repo}
```

### Step 2: Locate the Skill

```bash
# Verify the skill exists at the parsed path
ls /tmp/{repo}/{path/to/skill}/
```

The skill directory should contain at minimum a `SKILL.md`. It may also contain supporting files (scripts/, references/, assets/, etc.).

### Step 3: Copy to Target

```bash
# Copy the entire skill directory
cp -r /tmp/{repo}/{path/to/skill} {target-location}/{skill-name}
```

Where `{target-location}` is one of the skill locations from the table above (usually `modules/home-manager/features/ai-tools/common/skills/general/`).

### Step 4: Clean Up

```bash
rm -rf /tmp/{repo}
```

**Always clean up after copying.** Do not leave cloned repos in `/tmp`.

## Adding New Skills from Upstream

When adding a skill from an external source for the first time:

1. **Parse the URL** to extract clone URL, branch, and skill path (see URL Parsing above)
2. **Clone and copy** using the Clone-to-/tmp Workflow above
3. **Fix the frontmatter** in the copied SKILL.md:
   - Add the `upstream` field set to the original GitHub tree URL
   - Remove any `license`, `source`, or other non-standard tracking fields — `upstream` is the canonical provenance field
   - Verify `name` and `description` are present and accurate
4. **Genericize** all vendor-specific references (see Genericize section below)
5. **Verify** with `nix flake check --no-build`

## Update Workflow

### Step 1: Identify Skills to Update

List all skills with `upstream` fields and their source URLs:

```bash
grep -r '^upstream:' modules/home-manager/features/ai-tools/common/skills/ --include="SKILL.md"
```

### Step 2: Clone and Compare

For each skill (or batch of skills from the same repo):

1. **Parse the `upstream` URL** to extract clone URL, branch, and skill path
2. **Clone the repo** to `/tmp` using the Clone-to-/tmp Workflow
3. **Compare** the upstream version with the local version:

```bash
diff /tmp/{repo}/{path/to/skill}/SKILL.md {local-skill-dir}/SKILL.md
```

Also check for new or removed supporting files:

```bash
diff -rq /tmp/{repo}/{path/to/skill}/ {local-skill-dir}/
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

### Step 5: Clean Up and Verify

```bash
# Remove the clone
rm -rf /tmp/{repo}

# Verify the flake
nix flake check --no-build
```

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
- Editing **project-specific skills** in `.agents/skills/` — those serve this repo specifically
- Creating **brand new skills from scratch** — use the `skill-creator` skill instead
