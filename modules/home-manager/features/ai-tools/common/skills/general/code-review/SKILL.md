---
name: code-review
description: "Comprehensive code review for local diffs and GitHub PRs. Supports git/jj diff review and gh CLI PR workflows with severity-ranked findings, confidence scoring, and professional feedback."
upstream: "https://github.com/wshobson/agents/blob/main/plugins/developer-essentials/skills/code-review-excellence/SKILL.md"
---

# Code Review

A systematic framework for evaluating code changes that ensures consistency, security, and maintainability while fostering professional growth.

**Trigger**: "review this code", "review this PR", "code review", "review my changes", "review PR #N"

**Modes**: Local Review (git/jj diff) | PR Review (gh CLI)

**Tools**: Bash (git, jj, gh, rg), Read, Grep, Write

---

## Core Principles

- **Respect and Empathy**: Critique the code, not the person. Every line represents effort.
- **Constructive Feedback**: Every finding must lead toward a better solution with clear alternatives.
- **Specificity**: Reference exact lines and provide code examples. Vague feedback is useless.
- **Educational Value**: Use reviews to share knowledge about patterns, security, and performance.
- **Code Health Over Perfection**: Approve changes that improve overall code health, even if they aren't perfect. Don't block progress for minor preferences. (Google)
- **Focus Human Review**: Keep reviews under 400 LOC per session. Automate style/formatting checks so human review can focus on architecture and business logic. (Microsoft)

### Anti-Patterns

- **Rubber stamps**: Approving with "LGTM" without thorough analysis
- **Endless cycles**: Moving goalposts or introducing new requirements late in review
- **Style battles**: Forcing your stylistic preferences over equally valid alternatives
- **Hostile tone**: Sarcasm, condescension, or personal attacks
- **Preference blocking**: Holding up a merge for non-correctness issues

---

## Review Modes

### Local Review

For uncommitted or recently committed changes in the current workspace.

```bash
# Git
git diff --stat
git diff
git log --oneline -10

# Jujutsu
jj diff --stat
jj diff
jj log -r 'all()' --limit 10
```

1. Run `diff --stat` to understand the scope and distribution of changes.
2. Examine the full diff to identify logic and structural changes.
3. Check recent history to understand the context of current work.
4. Gather codebase context using Phase 1.5 below (at minimum Layers 1-2).
5. Proceed to the Review Process below.

### PR Review (gh CLI)

Full GitHub pull request workflow with structured feedback.

**Pipeline:**

1. **Gather context**: `gh pr view <number>` — read title, body, author, labels, linked issues.
2. **Fetch diff**: `gh pr diff <number>` — get the full changeset.
3. **Collect existing feedback first**: review existing PR discussion before drafting anything new.

```bash
# General PR conversation
gh pr view <number> --comments

# Line-specific review comments
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# Review summaries / states
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate
```

Build a quick list of issues other reviewers already raised. Treat those points as already covered unless you have materially different evidence, a different root cause, or a more precise remediation.

4. **Gather codebase context**: Expand understanding outward from the diff using the structured protocol in Phase 1.5 below. Depth depends on PR risk — at minimum, read full files and find callers of changed functions.
5. **Systematic review**: Follow the Review Process below.
6. **Submit review to GitHub** — always post the review. Never just show it in conversation.

Build a temporary JSON file containing the summary body, verdict event, and any inline comments, then submit it as a single atomic review. This ensures the summary appears in the Conversation tab and inline comments appear in the Files Changed tab, all grouped as one review.

```bash
# 1. Determine owner/repo and head commit
OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
HEAD_OID=$(gh pr view <number> --json headRefOid -q .headRefOid)

# 2. Build the review payload as a JSON file
cat > /tmp/review.json << 'REVIEW_EOF'
{
  "body": "## Code Review Summary\n\n...",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/file.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "**[BLOCKER]** Brief title\n\n**Issue**: ...\n**Why it matters**: ...\n**Suggestion**:\n```lang\n// fix\n```"
    }
  ]
}
REVIEW_EOF

# 3. Submit the review (inline comments + summary in one call)
gh api repos/${OWNER_REPO}/pulls/<number>/reviews --input /tmp/review.json
```

Set `event` based on verdict:

| Verdict | `event` value |
| --- | --- |
| Approve | `APPROVE` |
| Request changes | `REQUEST_CHANGES` |
| Comment only | `COMMENT` |

The `comments` array contains inline comments that appear in the Files Changed tab. Each entry needs `path`, `line`, `side` (always `"RIGHT"` for new code), and `body`. Omit the `comments` array if no line-specific findings — the summary body still posts as a review comment.

If the review has no inline findings at all (e.g., a simple approval), you can use the simpler CLI form instead:

```bash
gh pr review <number> --approve --body "..."
gh pr review <number> --request-changes --body "..."
```

---

## Review Process

### Phase 1: Context and Scope (2-3 min)

- Read the PR description and commit messages carefully.
- Understand the problem being solved and the proposed approach.
- Map out which files changed and how they interact with the broader system.
- Check for linked issues, related PRs, or migration dependencies.
- Read existing PR comments and reviews before drafting feedback. Note which concerns are already raised, who raised them, and whether they are still unresolved.

### Phase 1.5: Codebase Context Gathering

Before evaluating architecture or correctness, build a working model of how the changed code fits into the system. Work outward from the diff in layers. Scale depth to PR risk.

**Layer 1 — Full file read** (always)

Read the COMPLETE file for every changed file, not just diff hunks. The diff alone hides surrounding invariants, sibling functions, and class structure that affect whether the change is correct.

**Layer 2 — Direct dependents and dependencies** (always)

For each changed file, identify:
- What it imports (dependencies) — read key imported modules to understand the contracts the changed code relies on.
- What imports it (dependents) — find with `rg "import.*from.*<module>"` or `rg "require.*<module>"` across the repo. These are the files that may break.

For each changed function, class, type, or exported symbol:
- Find all callers: `rg "<symbol>\b" --type <lang>` across the repo.
- Check whether signature, return type, or behavioral changes break any caller.

**Layer 3 — Data flow tracing** (when changes touch I/O, APIs, or user input)

Trace data through the change end-to-end:
- Where does input originate? (API endpoint, UI form, message queue, cron job)
- What transformations or validations does it pass through?
- Where does it end up? (DB write, rendered output, external API call, log)

Read each file along the path, not just the changed ones. This catches missing validation, auth gaps, and injection points that live outside the diff.

**Layer 4 — Convention sampling** (when changes introduce new patterns or touch unfamiliar areas)

Find 2-3 existing files that do something similar:
- `rg -l "<pattern>" --type <lang>` or browse sibling files in the same directory.
- Compare error handling, naming, structure, logging, and test patterns.
- Flag deviations from the dominant codebase convention.

**Layer 5 — History and churn** (when changes touch complex or bug-prone areas)

```bash
# Recent change velocity — high churn = higher scrutiny
git log --oneline -10 -- <changed_file>

# When was this symbol last modified and why?
git log --oneline --all -S "<changed_function>" -- <changed_file>

# Who owns this area? (for context, not blame)
git shortlog -sn --no-merges -- <changed_file>
```

**Depth control** — scale to risk:

| PR Risk Level | Examples | Layers |
| --- | --- | --- |
| Trivial | Docs, config, formatting, typo fixes | 1 only |
| Standard | Feature work, refactors, test additions | 1-2 |
| Risky | Auth, payments, DB schema, public API, concurrency | 1-5 |

When in doubt, do at least Layers 1-2. A review without caller analysis misses breaking changes.

### Phase 2: High-Level Architecture (5-10 min)

- Does the change fit the existing architecture and conventions?
- Are there design concerns: tight coupling, missing abstractions, separation of concerns violations?
- Is this the simplest reasonable approach for the problem?
- Does this introduce technical debt that should be addressed now?
- Are there simpler alternatives worth proposing?

### Phase 3: Line-by-Line Analysis (10-20 min)

| Dimension      | What to Look For                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| Correctness    | Logic errors, off-by-one, null/undefined handling, edge cases, boundary conditions                      |
| Security       | Input validation, injection points (SQL, XSS, command), auth/authz gaps, secrets exposure, OWASP top 10 |
| Performance    | N+1 queries, heavy allocations in loops, algorithm complexity, resource leaks, missing pagination       |
| Concurrency    | Race conditions, deadlocks, unsafe shared mutable state, missing locks/atomic operations                |
| Error Handling | Swallowed exceptions, missing error context, improper error propagation, empty catch blocks             |
| Testing        | Coverage of new logic, edge case tests, test quality (meaningful assertions, not just existence)        |
| Observability  | Logging for debugging, metrics for monitoring, tracing for distributed systems                          |
| Code Quality   | Naming clarity, function length/complexity, DRY violations, single responsibility                       |

### Phase 4: Summary and Verdict (2-3 min)

- Compile findings into the structured output template.
- Filter out duplicate findings that are already present in the PR discussion unless your comment adds materially new information.
- Assign a confidence score.
- Render verdict: APPROVE, REQUEST_CHANGES, or COMMENT.

---

## Severity System

| Tag            | Meaning                                                                | Action Required           |
| -------------- | ---------------------------------------------------------------------- | ------------------------- |
| `[BLOCKER]`    | Security vulnerability, data loss risk, crash, correctness bug         | Must fix before merge     |
| `[MAJOR]`      | Logic error, missing edge case, architectural violation, missing tests | Must fix or justify       |
| `[SUGGESTION]` | Refactoring opportunity, readability improvement, optimization         | Recommended, not blocking |
| `[NIT]`        | Style, naming preference, trivial formatting                           | Optional, author's call   |
| `[KUDOS]`      | Exemplary code, clever solution, good pattern usage                    | No action — recognition   |

---

## Feedback Techniques

- **Question Approach**: Frame critiques as inquiries. "What happens if this input is empty?" is more effective than "This fails on empty input."
- **Suggest, Don't Command**: Offer alternatives as possibilities. "Consider using a Map here for O(1) lookups" instead of "Use a Map."
- **Differentiate Severity**: Always tag findings so the author can prioritize what's essential vs. what's a preference.
- **Explain the Why**: Provide rationale, not just the what. "This should be private to prevent external mutation" explains the benefit.
- **Acknowledge Good Work**: Use `[KUDOS]` to highlight well-written sections. Reinforces high standards and builds trust.
- **Be Specific**: Include code snippets in suggestions. Reduce the author's cognitive load when implementing fixes.

### De-duplicate Against Existing Comments

- Read existing review threads before posting any new summary or inline comment.
- Do not post the same issue again just because you found it independently.
- If another reviewer already raised the same underlying problem, prefer replying in that thread or omit the comment entirely.
- Add a new comment only when you have something materially new: a different root cause, a higher-severity impact, a more accurate file/line, or a concrete fix that the existing thread lacks.
- When in doubt, collapse duplicates. The goal is signal, not vote-counting.

---

## Confidence Scoring

Rate overall review confidence on a 1-5 scale.

| Score | Meaning                                                         |
| ----- | --------------------------------------------------------------- |
| 5/5   | Trivial or perfectly understood change, full context            |
| 4/5   | Well-understood change, minor areas of uncertainty              |
| 3/5   | Moderate complexity, some logic paths or side effects unclear   |
| 2/5   | Complex change, significant uncertainty or domain unfamiliarity |
| 1/5   | Very complex, likely issues missed                              |

**Adjustment rules** — subtract 1 for each that applies:

- Database migrations or schema changes
- Authentication or security-sensitive logic
- Complex concurrency or lock management
- Large-scale cross-cutting refactors
- Missing or inadequate test coverage
- Unfamiliar language or domain

### File-Level Confidence Table

Include in the review summary when the PR touches multiple files with varying complexity:

```
| File | Confidence | Notes |
|------|------------|-------|
| src/auth/login.ts | 2/5 | Auth logic, unfamiliar JWT library |
| src/utils/format.ts | 5/5 | Pure utility, straightforward |
| migrations/003_add_index.sql | 3/5 | Schema change, needs DBA review |
```

---

## Language-Specific Patterns

### Python

Bad — no types, no resource management, no error handling:

```python
def get_user_data(id):
    f = open("data.json")
    data = json.load(f)
    return data[id]
```

Good — typed, safe resource management, defensive:

```python
def get_user_data(user_id: str) -> dict:
    try:
        with open("data.json", "r") as f:
            data = json.load(f)
            return data.get(user_id, {})
    except (FileNotFoundError, json.JSONDecodeError) as e:
        logger.error("Failed to load user data for %s: %s", user_id, e)
        return {}
```

Key patterns to check:

- Type hints on function signatures and return types
- Context managers (`with`) for file/resource handling
- List comprehensions over loop-and-append
- Specific exceptions, never bare `except:`

### TypeScript

Bad — `any` types, no error handling:

```typescript
async function update(data: any) {
  const result = await api.post("/update", data);
  return result.data;
}
```

Good — typed interface, proper error handling:

```typescript
interface UpdatePayload {
  name: string;
  value: number;
}
interface UpdateResponse {
  success: boolean;
  id: string;
}

async function update(data: UpdatePayload): Promise<UpdateResponse> {
  const response = await api.post<UpdateResponse>("/update", data);
  return response.data;
}
```

Key patterns to check:

- Strict null checks and proper type narrowing (no `as any`)
- Typed error handling (not `catch(e: any)`)
- Async/await with proper cleanup (AbortController for cancellation)
- Guard clauses over deeply nested conditionals

### General (Any Language)

**N+1 Query Detection:**

- Bad: `SELECT * FROM posts WHERE user_id = ?` inside a user loop
- Good: `SELECT * FROM posts WHERE user_id IN (?)` before the loop with eager loading

**Security:**

- XSS: Use `textContent` over `innerHTML` for user-provided strings
- SQL Injection: Always use parameterized queries; never concatenate user input into SQL
- Auth: Verify authentication AND authorization on every protected endpoint

---

## Output Templates

### Inline vs Summary Strategy

The atomic review API (see PR Review pipeline step 6) handles both inline and summary comments in one call. When building the review JSON:

- **Inline comments** (`comments` array): Findings tied to a specific file and line — most actionable because the author sees the issue exactly where it lives in the diff.
- **Summary body** (`body` field): Overall verdict, architectural concerns spanning files, findings not pinnable to a single line.

| Finding type | Where it goes |
| --- | --- |
| BLOCKER / MAJOR with a clear file:line | `comments` array entry |
| Architectural / cross-cutting concern | `body` summary |
| Overall verdict + strengths | `body` summary |
| SUGGESTION / NIT on a specific line | `comments` array entry (keep brief) |

Avoid 20+ inline comments — group related nits into the summary. Each inline comment should stand alone and be actionable without reading the full summary.

### Review Summary

Use this template for both local and PR reviews:

````markdown
## Code Review Summary

**Scope**: [Brief description of the changes]
**Files Changed**: [N files, +X/-Y lines]
**Confidence**: [N/5] — [Brief justification]

### Findings

| Sev | Severity     | File                | Description       |
| --- | ------------ | ------------------- | ----------------- |
| B1  | [BLOCKER]    | path/to/file.ts:42  | Brief description |
| M1  | [MAJOR]      | path/to/other.py:15 | Brief description |
| S1  | [SUGGESTION] | path/to/lib.rs:88   | Brief description |

### Details

<details>
<summary><strong>B1. [BLOCKER] Brief title — path/to/file.ts:42</strong></summary>

**Issue**: Description of the problem.
**Why it matters**: Impact explanation (security risk, data loss, crash).
**Suggestion**:
`typescript
    // proposed fix
    `
**Test to add**: Description of a test case that would catch this.

</details>

<details>
<summary><strong>M1. [MAJOR] Brief title — path/to/other.py:15</strong></summary>

**Issue**: ...
**Why it matters**: ...
**Suggestion**: ...

</details>

### File-Level Confidence

| File             | Confidence | Notes                 |
| ---------------- | ---------- | --------------------- |
| path/to/file.ts  | 3/5        | Complex auth logic    |
| path/to/other.py | 5/5        | Simple utility change |

### Strengths

- [Thing done well]
- [Another positive observation]

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT

[Brief justification for the verdict]
````

### GitHub Comment Formatting Rules

When posting comments to GitHub (both inline and summary):

- **Never use `#N` notation** (e.g., `#1`, `#2`, `#3`) — GitHub auto-links these to issues/PRs, creating broken references. Use severity-prefixed IDs instead: `B1`, `M1`, `S1`, `N1` (for Blocker, Major, Suggestion, Nit).
- **Never reference findings as "issue #1"** — write "finding B1" or just use the severity tag.
- Keep inline comment bodies self-contained — the author reads them in the diff without needing context from the summary.
- Before posting, verify each comment is net-new relative to existing PR discussion. If the same issue already exists, extend that thread instead of creating another top-level comment.
---

## Guidelines

**DO:**

- Understand context and purpose before reading code
- Provide specific, actionable feedback with code examples
- Explain WHY something is an issue, not just WHAT
- Acknowledge good patterns and well-written code
- Ask clarifying questions when intent is unclear
- Focus on correctness, security, and maintainability over style
- Keep review scope to the actual changes
- Adjust depth based on change risk (auth change > typo fix)
- Check existing PR comments first and avoid repeating points already made by others

**DON'T:**

- Rubber-stamp with "LGTM" without real inspection
- Block merges over style preferences or personal taste
- Use condescending, sarcastic, or hostile language
- Nitpick formatting that automated tools should catch
- Review more than 400 lines without breaking into sessions
- Demand a complete rewrite of the author's valid approach
- Ignore test coverage gaps
- Mix unrelated feedback or feature requests into the review
- Post duplicate comments when the same concern is already captured elsewhere in the PR
