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
4. Proceed to the Review Process below.

### PR Review (gh CLI)

Full GitHub pull request workflow with structured feedback.

**Pipeline:**

1. **Gather context**: `gh pr view <number>` — read title, body, author, labels, linked issues.
2. **Fetch diff**: `gh pr diff <number>` — get the full changeset.
3. **Understand codebase**: Read files surrounding the changes. Use `rg` to find related usages of changed functions/variables across the repo.
4. **Systematic review**: Follow the Review Process below.
5. **Post results**:

```bash
# Summary comment
gh pr review <number> --comment --body "..."

# Approve
gh pr review <number> --approve --body "..."

# Request changes
gh pr review <number> --request-changes --body "..."

# Inline comment on a specific file and line
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="**[MAJOR]** Issue description..." \
  -f commit_id="$(gh pr view <number> --json headRefOid -q .headRefOid)" \
  -f path="src/file.ts" \
  -F line=42 \
  -f side="RIGHT"
```

---

## Review Process

### Phase 1: Context and Scope (2-3 min)

- Read the PR description and commit messages carefully.
- Understand the problem being solved and the proposed approach.
- Map out which files changed and how they interact with the broader system.
- Check for linked issues, related PRs, or migration dependencies.

### Phase 2: High-Level Architecture (5-10 min)

- Does the change fit the existing architecture and conventions?
- Are there design concerns: tight coupling, missing abstractions, separation of concerns violations?
- Is this the simplest reasonable approach for the problem?
- Does this introduce technical debt that should be addressed now?
- Are there simpler alternatives worth proposing?

### Phase 3: Line-by-Line Analysis (10-20 min)

| Dimension | What to Look For |
|-----------|-----------------|
| Correctness | Logic errors, off-by-one, null/undefined handling, edge cases, boundary conditions |
| Security | Input validation, injection points (SQL, XSS, command), auth/authz gaps, secrets exposure, OWASP top 10 |
| Performance | N+1 queries, heavy allocations in loops, algorithm complexity, resource leaks, missing pagination |
| Concurrency | Race conditions, deadlocks, unsafe shared mutable state, missing locks/atomic operations |
| Error Handling | Swallowed exceptions, missing error context, improper error propagation, empty catch blocks |
| Testing | Coverage of new logic, edge case tests, test quality (meaningful assertions, not just existence) |
| Observability | Logging for debugging, metrics for monitoring, tracing for distributed systems |
| Code Quality | Naming clarity, function length/complexity, DRY violations, single responsibility |

### Phase 4: Summary and Verdict (2-3 min)

- Compile findings into the structured output template.
- Assign a confidence score.
- Render verdict: APPROVE, REQUEST_CHANGES, or COMMENT.

---

## Severity System

| Tag | Meaning | Action Required |
|-----|---------|-----------------|
| `[BLOCKER]` | Security vulnerability, data loss risk, crash, correctness bug | Must fix before merge |
| `[MAJOR]` | Logic error, missing edge case, architectural violation, missing tests | Must fix or justify |
| `[SUGGESTION]` | Refactoring opportunity, readability improvement, optimization | Recommended, not blocking |
| `[NIT]` | Style, naming preference, trivial formatting | Optional, author's call |
| `[KUDOS]` | Exemplary code, clever solution, good pattern usage | No action — recognition |

---

## Feedback Techniques

- **Question Approach**: Frame critiques as inquiries. "What happens if this input is empty?" is more effective than "This fails on empty input."
- **Suggest, Don't Command**: Offer alternatives as possibilities. "Consider using a Map here for O(1) lookups" instead of "Use a Map."
- **Differentiate Severity**: Always tag findings so the author can prioritize what's essential vs. what's a preference.
- **Explain the Why**: Provide rationale, not just the what. "This should be private to prevent external mutation" explains the benefit.
- **Acknowledge Good Work**: Use `[KUDOS]` to highlight well-written sections. Reinforces high standards and builds trust.
- **Be Specific**: Include code snippets in suggestions. Reduce the author's cognitive load when implementing fixes.

---

## Confidence Scoring

Rate overall review confidence on a 1-5 scale.

| Score | Meaning |
|-------|---------|
| 5/5 | Trivial or perfectly understood change, full context |
| 4/5 | Well-understood change, minor areas of uncertainty |
| 3/5 | Moderate complexity, some logic paths or side effects unclear |
| 2/5 | Complex change, significant uncertainty or domain unfamiliarity |
| 1/5 | Very complex, likely issues missed |

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
  const result = await api.post('/update', data);
  return result.data;
}
```

Good — typed interface, proper error handling:
```typescript
interface UpdatePayload { name: string; value: number; }
interface UpdateResponse { success: boolean; id: string; }

async function update(data: UpdatePayload): Promise<UpdateResponse> {
  const response = await api.post<UpdateResponse>('/update', data);
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

### Review Summary

Use this template for both local and PR reviews:

```markdown
## Code Review Summary

**Scope**: [Brief description of the changes]
**Files Changed**: [N files, +X/-Y lines]
**Confidence**: [N/5] — [Brief justification]

### Findings

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | [BLOCKER] | path/to/file.ts:42 | Brief description |
| 2 | [MAJOR] | path/to/other.py:15 | Brief description |
| 3 | [SUGGESTION] | path/to/lib.rs:88 | Brief description |

### Details

#### 1. [BLOCKER] Brief title — path/to/file.ts:42
**Issue**: Description of the problem.
**Why it matters**: Impact explanation (security risk, data loss, crash).
**Suggestion**:
    ```typescript
    // proposed fix
    ```
**Test to add**: Description of a test case that would catch this.

### File-Level Confidence

| File | Confidence | Notes |
|------|------------|-------|
| path/to/file.ts | 3/5 | Complex auth logic |
| path/to/other.py | 5/5 | Simple utility change |

### Strengths
- [Thing done well]
- [Another positive observation]

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT
[Brief justification for the verdict]
```

### Per-File Comment (PR Mode)

For inline comments posted via `gh api`:

```markdown
**[SEVERITY]** Brief title

**Issue**: What's wrong on this line.
**Why it matters**: Why this needs to change.
**Suggestion**:
    ```
    // code fix
    ```
```

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

**DON'T:**
- Rubber-stamp with "LGTM" without real inspection
- Block merges over style preferences or personal taste
- Use condescending, sarcastic, or hostile language
- Nitpick formatting that automated tools should catch
- Review more than 400 lines without breaking into sessions
- Demand a complete rewrite of the author's valid approach
- Ignore test coverage gaps
- Mix unrelated feedback or feature requests into the review
