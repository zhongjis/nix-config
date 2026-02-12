---
name: github-pr-management
description: "(project - Skill) Manage GitHub pull requests: create/update PR descriptions, add/edit PR comments, review PRs. Triggers on: 'create PR', 'update PR description', 'comment on PR', 'review PR', 'edit PR', 'PR summary', 'add PR comment', or any reference to pull request management. Use when the user wants to write, edit, or manage PR descriptions, comments, or reviews on GitHub Enterprise or github.com."
---

# GitHub PR Management

## GitHub Enterprise API

Use `gh` CLI with `GH_HOST` for enterprise instances:

```bash
# Set host for enterprise
export GH_HOST=git.corp.adobe.com

# View PR
gh pr view <number> --repo <org>/<repo> --json body,title

# Edit PR description
gh pr edit <number> --repo <org>/<repo> --body "$BODY"

# List PR comments
gh api repos/<org>/<repo>/issues/<number>/comments --jq '.[] | {id, body: (.body | .[0:100])}'

# Update a specific comment
gh api repos/<org>/<repo>/issues/comments/<comment_id> -X PATCH -F body="$BODY"

# Add a new comment
gh api repos/<org>/<repo>/issues/<number>/comments -f body="$BODY"
```

## PR Description

### 1. Check for PR Template

Always check for a PR template first:

```bash
# Common template locations
.github/PULL_REQUEST_TEMPLATE.md
.github/pull_request_template.md
docs/pull_request_template.md
PULL_REQUEST_TEMPLATE.md
```

If a template exists, follow its structure exactly. If not, use the format below.

### 2. Writing Style

- **Be concise.** Reviewers scan, not read. One-line summary, bullet changes, done.
- **No duplication.** If info exists in a companion PR or comment, link to it — don't repeat.
- **No prose paragraphs.** Use tables and bullets.
- **Precise change types.** Use the verb that matches: "Add" = new, "Update" = enhance existing, "Fix" = bug.

### 3. Description Structure

```markdown
## Summary

<1-2 sentences: what changed and why>

## Changes:
- [change_type] Concise description of change
- [change_type] Another change

## Footers:
- Change: https://jira.corp.adobe.com/browse/<TICKET>
- Epic: https://jira.corp.adobe.com/browse/<EPIC>
```

### 4. Change Types

| Type | When to Use |
|------|-------------|
| `bugfix` | Fix for incorrect behavior |
| `feature` | New functionality |
| `test` | Adding or fixing tests only |
| `perf` | Performance improvement |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, no logic change |
| `refactor` | Code restructure, no behavior change |

Format: `- [feature] Added X` or `- [bugfix] Fixed Y`

### 5. Footers

| Footer | Required | Description |
|--------|----------|-------------|
| `Change` | **Yes** | JIRA ticket. `Change: https://jira.corp.adobe.com/browse/CET-1234` |
| `Epic` | **Yes** | JIRA epic. `Epic: https://jira.corp.adobe.com/browse/CET-5678` |
| `BREAKING_CHANGE` | No | Presence = major version bump |
| `REBUILD_DOWNSTREAM` | No | Rebuild listed libs on main. `REBUILD_DOWNSTREAM: akka-common, marketo-core` |
| `BUMP_DOWNSTREAM` | No | **High risk.** Patch downstream version branches. Only on version branch merges. |
| `UNSTABLE_VERSIONS` | No | Versions that won't get this fix. `UNSTABLE_VERSIONS: 1.4.X, 1.5.X` |

### 6. Companion PRs

When changes span multiple repos, link companion PRs:

```markdown
### Companion PR
[repo-name #N](url) — one-line description
```

## PR Comments

- Use comments for supplementary context (flowcharts, diagrams, design rationale) that doesn't belong in the description.
- Keep comments self-contained — reader shouldn't need to cross-reference the description to understand the comment.
- No duplication with PR description. If the description covers it, don't repeat in comments.
- Mermaid diagrams are supported — use for flow visualization.

## PR Review Comments

When reviewing code, be:
- **Specific**: Point to exact lines, suggest exact fixes
- **Constructive**: "Consider X because Y" not "This is wrong"
- **Scoped**: Comment on what changed, not pre-existing issues
