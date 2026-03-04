---
name: skill-updater
description: "Update AI agent skills in this Nix config repository. Use when the user wants to update skills from upstream sources, add new skills from external repositories, check which skills need updates, sync skills with their upstream, or manage skill provenance tracking. Triggers on requests like 'update skills', 'sync skills from upstream', 'check for skill updates', 'add skill from [URL]', 'which skills are from upstream?', or 'update the anthropic skills'."
---

# Skill Updater

Update and manage AI agent skills installed in this nix-config repository via Home Manager.

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

## Update Workflow

### Step 1: Identify Skills to Update

List all skills with `upstream` fields and their source URLs:

```bash
grep -r '^upstream:' modules/home-manager/features/ai-tools/common/skills/ --include="SKILL.md"
```

### Step 2: Fetch Upstream Content

For each skill with an `upstream` field, fetch the latest SKILL.md from the source.

**For GitHub-hosted skills**, convert the tree URL to a raw content URL:
- Tree URL: `https://github.com/org/repo/tree/main/skills/name`
- Raw URL: `https://raw.githubusercontent.com/org/repo/main/skills/name/SKILL.md`

Fetch multiple skills in parallel for efficiency. Also check for additional files in the upstream skill directory (scripts/, references/, assets/) that may have been added.

### Step 3: Compare Upstream with Local

For each skill, compare the fetched upstream content with the local version:

1. **Frontmatter**: Note any new fields (ignore `upstream` differences — that's ours)
2. **Body content**: Identify new sections, removed sections, and modified content
3. **Supporting files**: Check if upstream added new scripts/, references/, or assets/

Categorize each skill:
- ✅ **Up to date** — No meaningful content changes
- ⚠️ **Needs update** — New content, fixes, or improvements available
- 🔍 **Needs review** — Changes exist but may be heavily vendor-specific (skip or genericize)

### Step 4: Apply Updates

For skills that need updating:

1. Add new sections/content from upstream
2. Apply fixes and improvements
3. Preserve all local customizations not present upstream (especially genericizations)
4. Do NOT blindly overwrite — merge intelligently

### Step 5: Genericize (MANDATORY)

**All skills must be vendor-neutral.** Apply these replacements to any new content:

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

### Step 6: Verify

```bash
nix flake check --no-build
```

This validates the flake structure. Skills are markdown files so they won't cause Nix evaluation errors, but verify anyway to ensure nothing else was accidentally broken.

## Adding New Skills from Upstream

When adding a skill from an external source for the first time:

1. Create the skill directory under the appropriate location (usually `general/`)
2. Copy the upstream SKILL.md content
3. Add the `upstream` field to frontmatter pointing to the source URL
4. Remove any `license`, `source`, or other non-standard tracking fields — `upstream` is the canonical field
5. Genericize ALL vendor-specific references per the table above
6. Copy any supporting files (scripts/, references/, assets/) that the skill needs
7. Verify with `nix flake check --no-build`

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
