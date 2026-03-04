---
name: address-review
upstream: "https://github.com/v1-io/v1tamins/tree/main/claude/skills/address-review"
description: >
  Use when addressing PR review comments from Copilot, bots, or humans.
  Triggers on "fix review comments", "address Copilot feedback", "respond to PR comments".
---

# Address PR Review Comments

Fetch code review comments on a PR (from Copilot, bots, or humans), critically evaluate each one, fix the valid issues, and reply to each comment.

## Workflow

### 0. Checkout the PR Branch

Before touching any code, ensure you are on the correct branch:

```bash
# Extract branch name and switch to it
gh pr checkout <PR_NUMBER>
```

If the PR is from a fork or the branch doesn't exist locally, `gh pr checkout` handles that automatically.

### 1. Fetch Unreplied Comments

Check **both** comment types:

**Line-specific review comments** (code-level):
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --paginate | \
jq '[.[] | select(.in_reply_to_id == null)] as $originals |
     [.[] | .in_reply_to_id] as $replied_ids |
     $originals | map(select(.id as $id | $replied_ids | index($id) | not))'
```

**General PR-level comments** (issue-level):
```bash
# Fetch all, then filter out known bot noise (deployment bots, CI, etc.)
gh api repos/{owner}/{repo}/issues/{pr}/comments --paginate | \
jq '[.[] | select(
  (.user.type != "Bot") and
  (.body | test("^\\[vc\\]:|^\\[deploy|^<!-- |^## Deploy|^This pull request is automatically built"; "i") | not)
)]'
```

> **Note:** The general comment filter excludes common bot patterns (Vercel, Netlify, Render, CI). Adjust the regex if your project uses other bots that produce non-review noise.

If no unreplied comments exist, report that and stop.

### 2. Evaluate and Fix

For each unreplied comment, read the relevant file and code section, then classify:

| Verdict | Action |
|---------|--------|
| **Valid** | Implement fix following existing patterns |
| **Partial** | Implement appropriate fix addressing the core concern |
| **Invalid** | Document reason for skipping |

**Evaluation heuristics:**
- Unused imports, duplicate calls, outdated docs, stale mocks → usually valid
- Performance suggestions → evaluate if impact is meaningful
- Refactoring suggestions → evaluate against KISS/YAGNI
- Security suggestions → take seriously, verify vulnerability is real

### 3. Reply to Each Comment

**Line-specific**: `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -f body="..."`
**General PR-level**: `gh api repos/{owner}/{repo}/issues/{pr}/comments -f body="..."`

Keep replies brief:
- Valid: "Fixed" or "Fixed - [note if approach differs]"
- Invalid: "Skipped - [brief reason]"
- Partial: "Addressed - [note on approach]"

### 4. Commit and Push

Commit all fixes with a descriptive message. Ask the user before pushing.

## Output

Summary table of all comments addressed:

| # | File:Line | Issue | Action | Reply |
|---|-----------|-------|--------|-------|
| 1 | path.py:42 | Unused import | Fixed | Fixed |
| 2 | test.py:100 | Incorrect mock | Fixed | Fixed |
| 3 | utils.py:50 | Suggested refactor | Skipped | Not needed per YAGNI |
