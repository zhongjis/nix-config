# PR Workflow

GitHub pull-request specifics for the PR Review mode. Loaded only when reviewing a PR; local reviews never need this file.

## 1. Gather PR context

- `gh pr view <number>` — title, body, author, labels, linked issues. The body and linked issues are a Spec source — fetch the linked issues or tickets to ground the Spec axis.
- `gh pr diff <number>` — the full changeset.

## 2. Collect existing feedback first

Before drafting anything, read the full PR discussion:

```bash
gh pr view <number> --comments                                 # general conversation
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate # line-specific comments
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate  # review summaries / states
```

Treat issues other reviewers already raised as prior art — your findings must be net-new. Reply in the existing thread rather than reposting; add a fresh comment only with materially new information (a different root cause, higher severity, a more precise line, or a fix the thread lacks). When in doubt, collapse the duplicate — the goal is signal.

## 3. Submit as one atomic review

Build a temporary JSON file with the summary body, verdict event, and any inline comments, then submit it as a single review, so the summary lands in the Conversation tab and the inline comments in the Files Changed tab, grouped as one review.

```bash
# 1. Determine owner/repo and head commit
OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
HEAD_OID=$(gh pr view <number> --json headRefOid -q .headRefOid)

# 2. Build the review payload
cat > /tmp/review.json << 'REVIEW_EOF'
{
  "body": "## Code Review Summary\n\n...",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/file.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "**[BLOCKER] (Security)** Brief title\n\n**Issue**: ...\n**Why it matters**: ...\n**Suggestion**:\n```lang\n// fix\n```"
    }
  ]
}
REVIEW_EOF

# 3. Submit (inline comments + summary in one call)
gh api repos/${OWNER_REPO}/pulls/<number>/reviews --input /tmp/review.json
```

Set `event` from the verdict:

| Verdict | `event` |
| --- | --- |
| Approve | `APPROVE` |
| Request changes | `REQUEST_CHANGES` |
| Comment only | `COMMENT` |

Each `comments` entry needs `path`, `line`, `side` (`"RIGHT"` for new code), and `body`. Omit the array if there are no line-specific findings; the summary still posts. For a simple approval with no inline findings, the short form works:

```bash
gh pr review <number> --approve --body "..."
gh pr review <number> --request-changes --body "..."
```

## Inline vs summary

The summary is an index; the inlines are the content.

- A finding with a file and line: its full detail (issue, why it matters, fix, test to add) lives in the inline comment; the summary lists it as one row in the findings table (ID, axis, severity, location, one line).
- A cross-cutting finding with no single line: write it out in the summary body.
- Verdict, confidence, and strengths live in the summary only.

Don't restate inline content in the summary — GitHub renders them in different tabs, so duplication forces the author to read twice and drifts if one copy changes. Avoid 20+ inline comments; group related nits onto one representative line.

## Progressive disclosure in the summary

Keep the verdict and findings table above the fold. Genuinely secondary, summary-only sections — a long per-axis or per-file confidence table, strengths / KUDOS, methodology notes — can go in `<details>` blocks. Blockers and majors are never collapsed.

## GitHub comment formatting

- **Never use `#N` notation** (`#1`, `#2`) — GitHub auto-links it to issues/PRs, creating broken references. Use severity-prefixed IDs: `B1`, `M1`, `S1`, `N1`.
- **Never write "issue #1"** — write "finding B1", or use the severity tag.
- Keep inline comment bodies self-contained — the author reads them in the diff without the summary. Prefix each with its severity and axis, e.g. `**[MAJOR] (Regression)**`.
