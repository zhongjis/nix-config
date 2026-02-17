---
name: github-pr-management
description: "(project - Skill) Manage GitHub pull requests: create/update PR descriptions, add/edit PR comments, review PRs. Triggers on: 'create PR', 'update PR description', 'comment on PR', 'review PR', 'edit PR', 'PR summary', 'add PR comment', or any reference to pull request management. Use when the user wants to write, edit, or manage PR descriptions, comments, or reviews on GitHub Enterprise or github.com."
---

# GitHub PR Management

## Prerequisites: Authentication

Before any PR operation, verify `gh` CLI authentication:

```bash
gh auth status
```

- If authenticated: proceed.
- If NOT authenticated: **STOP. Prompt the user to configure `gh` CLI first** (`gh auth login`). Do not attempt any PR operations until auth succeeds.
- For enterprise GitHub instances: the user must have already authed via `gh auth login --hostname <host>`. The `gh` CLI routes to the correct host based on the repo's git remote. Do not manually set `GH_HOST`.

## Jira URL Parsing

When the user provides a Jira URL, extract the base URL and ticket key for use in Footers. **Do not fetch or interact with the Jira instance.**

Jira URLs follow this pattern: `https://<HOST>/browse/<TICKET_KEY>`

**Parse rules:**
- **JIRA_BASE_URL** = everything before `/browse/`
- **TICKET_KEY** = path segment after `/browse/`, stripped of trailing `/`, `?`, `#` and anything after
- Ticket keys match `<PROJECT>-<NUMBER>` (uppercase letters, hyphen, digits)

| Input URL | JIRA_BASE_URL | TICKET_KEY |
|-----------|---------------|------------|
| `https://jira.company.com/browse/PROJ-123` | `https://jira.company.com` | `PROJ-123` |
| `https://team.atlassian.net/browse/ENG-456?filter=open` | `https://team.atlassian.net` | `ENG-456` |
| `https://jira.internal.co/browse/PLAT-78/` | `https://jira.internal.co` | `PLAT-78` |

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
- **No duplication.** If info exists in a companion PR or comment, link to it -- don't repeat.
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
- Change: <JIRA_BASE_URL>/browse/<TICKET>
- Epic: <JIRA_BASE_URL>/browse/<EPIC>
```

**Variables:** If the user provided a Jira URL, parse it per the "Jira Ticket Integration" section above to extract JIRA_BASE_URL, TICKET_KEY, and EPIC. If no Jira URL was provided, prompt the user. If the user defers, use placeholders (`<JIRA_BASE_URL>`, `<TICKET>`, `<EPIC>`) and move on.

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
| `Change` | **Yes** | JIRA ticket. `Change: <JIRA_BASE_URL>/browse/<TICKET>` |
| `Epic` | **Yes** | JIRA epic. `Epic: <JIRA_BASE_URL>/browse/<EPIC>` |
| `BREAKING_CHANGE` | No | Presence = major version bump |
| `REBUILD_DOWNSTREAM` | No | Rebuild listed libs on main. `REBUILD_DOWNSTREAM: lib-a, lib-b` |
| `BUMP_DOWNSTREAM` | No | **High risk.** Patch downstream version branches. Only on version branch merges. |
| `UNSTABLE_VERSIONS` | No | Versions that won't get this fix. `UNSTABLE_VERSIONS: 1.4.X, 1.5.X` |

### 6. Companion PRs

When changes span multiple repos, link companion PRs:

```markdown
### Companion PR
[repo-name #N](url) -- one-line description
```

## PR Comments

- Use comments for supplementary context (flowcharts, diagrams, design rationale) that doesn't belong in the description.
- Keep comments self-contained -- reader shouldn't need to cross-reference the description to understand the comment.
- No duplication with PR description. If the description covers it, don't repeat in comments.
- Mermaid diagrams are supported -- use for flow visualization.

## PR Review Comments

When reviewing code, be:
- **Specific**: Point to exact lines, suggest exact fixes
- **Constructive**: "Consider X because Y" not "This is wrong"
- **Scoped**: Comment on what changed, not pre-existing issues
