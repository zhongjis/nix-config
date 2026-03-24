---
name: address-review
upstream: "https://github.com/openai/skills/tree/main/skills/.curated/gh-address-comments"
adaptedFrom:
  - "https://github.com/v1-io/v1tamins/tree/main/claude/skills/address-review"
description: >
  Use when addressing unresolved PR review comments or threads from Copilot, bots, or humans.
  Triggers on "fix review comments", "address Copilot feedback", "respond to PR comments",
  "resolve PR threads", and similar requests to work review feedback to closure.
---

# Address PR Review Threads

Address unresolved PR review threads end-to-end by gathering full context, deciding whether each thread needs a code change or a technical disagreement, applying the necessary changes, commenting in the thread, and resolving only the threads actually addressed.

## Trigger

Use this skill for requests like:

- "fix review comments"
- "address Copilot feedback"
- "respond to PR comments"
- "resolve PR threads"

The unit of work is the unresolved review thread, not just unreplied comments.

## Prerequisites

Before performing any PR operation:

1. Verify GitHub CLI authentication:

```bash
gh auth status
```

2. Ensure you are on the correct PR branch:

```bash
gh pr checkout <PR_NUMBER>
```

3. To retrieve structured comment and thread context, run:

```bash
python3 scripts/fetch_comments.py
```

This outputs a JSON blob with `pull_request`, `conversation_comments`, `reviews`, and `review_threads`. The script requires `gh` CLI to be authenticated.

If authentication fails or the PR branch cannot be checked out, stop and report the issue.

## Workflow

### 1. Discover Unresolved Threads

Identify unresolved review threads on the PR. The preferred method is running `python3 scripts/fetch_comments.py`, which provides a structured JSON view of all comments and threads. Alternatively, use `gh pr view --json reviewThreads` as a fallback.

If there are no unresolved threads, report that and stop.

### 2. Fetch Full Context for Each Thread

Before deciding what to do with a thread, gather all of the following:

- The full comment body and all replies in the thread
- The referenced file path and code location
- The current contents of the referenced file around that location
- The relevant diff hunk or patch context, if available

Read the thread end-to-end and de-duplicate against existing discussion:

- Do not restate points already made in the same thread unless you are adding materially new reasoning
- Prefer replying in the existing thread instead of creating parallel discussion elsewhere
- Keep the thread focused on the specific issue being addressed

Do not classify or act on a thread until you have read this context.

### 3. Classify Each Thread

For each unresolved thread, classify it as:

| Verdict      | Action                                                                      |
| ------------ | --------------------------------------------------------------------------- |
| **fix**      | Make a code change that addresses the concern                               |
| **disagree** | Reply with a concise technical explanation for keeping the current approach |

A narrower or partial code change is still a **fix** if it addresses the core valid concern.

**Evaluation heuristics:**

- Unused imports, duplicate calls, outdated docs, stale mocks -> usually **fix**
- Performance suggestions -> evaluate if impact is meaningful before changing code
- Refactoring suggestions -> evaluate against KISS/YAGNI and existing local patterns
- Security suggestions -> take seriously, verify the issue is real before acting

### 4. Present Plan to the User

Before making any external side effects, present a per-thread plan that includes:

- Thread identifier or short description
- Classification (`fix` or `disagree`)
- Files that will be touched, if any
- Brief explanation of the intended change or disagreement

Do not commit, push, comment, or resolve threads before the user approves.

### 5. Approval Boundary

After presenting the plan, ask for approval before any external side effects. Do not commit, push, comment in a thread, or resolve any thread before the user approves.

### 6. Apply Fixes

For every thread classified as **fix**:

- Read the relevant file(s) and surrounding code again if needed
- Implement the smallest change that addresses the concern
- Follow existing patterns and avoid unrelated refactors
- Track which thread or comment IDs were addressed by code changes

Do not defer valid fixes that are part of the approved plan.

### 7. Commit and Push If Code Changed

After the user approves, commit and push only if this pass includes code changes:

- In `jj` repositories, use `jj` commands for commit and push
- In git repositories, use git commands for commit and push

Use a single descriptive commit message that summarizes the review fixes.

### 8. Comment on Each Addressed Thread

After any required commit and push are complete, comment on each addressed thread before resolving it.

For every thread classified as **fix**:

- Reply in the existing thread
- Keep the reply brief and concrete
- State that the issue was fixed, and note if the final implementation differs from the original suggestion

For every thread classified as **disagree**:

- Reply in the existing thread
- Keep the reply brief, technical, and respectful
- Explain why the current implementation is preferable on correctness, maintainability, performance, or scope grounds

Do not use dismissive or vague replies.

If no code changes were required, this commenting step is the first external action after approval.

### 9. Resolve Addressed Threads

After the thread has a closing comment:

- Resolve only the threads actually addressed in this pass
- Do not resolve threads that remain unaddressed or still need user input

The resolution flow is always: comment first, then resolve.

Use the available GitHub tooling (`gh`, MCP, or equivalent) to post replies in the existing thread.

Keep replies brief:

- Fix: "Fixed" or "Fixed - [note if approach differs]"
- Disagree: "Not changing this - [brief technical reason]"

## Output

Provide a final summary that includes:

- Total unresolved threads found
- Number addressed with code changes
- Number addressed with disagreement replies
- Number intentionally left unresolved, with reasons
- Files changed
- Whether commit and push succeeded
- Number of threads commented on and resolved

Summary table of all reviewed threads:

| #   | File:Line   | Issue                    | Action    | Reply                               |
| --- | ----------- | ------------------------ | --------- | ----------------------------------- |
| 1   | path.py:42  | Unused import            | Fixed     | Fixed                               |
| 2   | test.py:100 | Incorrect mock           | Fixed     | Fixed                               |
| 3   | utils.py:50 | Suggested refactor       | Disagreed | Not changing - not needed per YAGNI |
| 4   | api.py:88   | Broader redesign request | Left open | Needs user decision on scope        |
