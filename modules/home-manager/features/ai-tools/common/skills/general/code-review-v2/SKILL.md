---
name: code-review-v2
description: "Multi-axis code review for local diffs (git/jj) and GitHub PRs — independent review axes reported as isolated passes so no axis masks another."
disable-model-invocation: true
adaptedFrom:
  - "https://github.com/wshobson/agents/blob/main/plugins/developer-essentials/skills/code-review-excellence/SKILL.md"
  - "https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md"
---

# Code Review

A review runs as a set of independent **axes** — each a single lens (correctness, standards, regression, security, and conditional spec / performance / tests / observability) that produces its own findings. Axes run as **isolated passes** and are reported side by side, so a pass on one axis never masks a fail on another.

**Modes**: Local Review (git/jj diff) | PR Review (gh CLI).

## Principles

- **Critique the code, not the person.** No sarcasm or condescension — every line represents effort.
- **Every finding leads to a better solution.** Cite the exact line, include a fix example, and explain *why* it matters. Vague feedback is useless.
- **Code health over perfection.** Approve changes that improve overall health even when imperfect; never block on style or personal preference.
- **Keep review focused.** Under 400 LOC per session — defect detection collapses past that. Let tooling catch formatting; spend human attention on architecture and behavior. Split larger changes.
- **Acknowledge good work.** Use `[KUDOS]` for exemplary sections — it reinforces standards.
- **Scope to the actual change.** Raise unrelated issues or feature ideas elsewhere, not in this review.

## Review process

Run these steps in order. Steps 1-3 run once, inline, in the main context and build the shared **foundation brief** that every axis reads.

1. **Pin scope + mode.** Fix the comparison point and note the mode.
   - Local: `git diff <base>...HEAD` (three-dot, so the comparison is against the merge-base) or `jj diff`; `git diff --stat` for scope; `git log <base>..HEAD --oneline` for commits.
   - PR: follow `references/pr-workflow.md` to gather PR metadata and the diff.
   - Confirm the base resolves (`git rev-parse <base>`) and the diff is non-empty before going further — a bad ref or empty diff fails here, not inside an axis.
2. **Gather context + fetch links.** Read each changed file in full, not just the hunks. For every changed symbol, find its callers. Follow any links you encounter — the PR description, commit messages, linked issues or tickets, a path the user passed — and fetch the ones your environment can reach, so behavior and intent rest on real context. Scale depth to risk (see Risk dial); `references/context-gathering.md` has the concrete caller / history / churn commands.
3. **Build the foundation brief.** Write down, once:
   - **Behavior delta** — what observable behavior the change adds, removes, or alters. This is descriptive, not a finding; it feeds every axis.
   - **Axis triage** — which axes apply and how deep. Record whether the diff touches any **security surface** (input boundary, auth/authz, secrets, deserialization, SQL / shell / HTML sinks, network, file paths) — that decides Security's depth.
4. **Select active axes.** From the Axis registry, activate every always-on axis plus each conditional axis whose trigger the triage hit.
5. **Run each active axis in isolation.** Dispatch the axes as isolated passes per the Execution rule (sub-agents whenever this environment exposes a task or sub-agent tool and the risk is not Trivial; otherwise inline). Each axis reads the foundation brief and its section in `references/axis-checklists.md`, then reports findings under its own heading — stating "no findings" when it finds nothing.
6. **Aggregate + verdict + post.** Combine per the Aggregation rules, render the verdict, and post (PR: via `references/pr-workflow.md`).

## Axis registry

| Axis | Runs when | Looks for | Checklist |
| --- | --- | --- | --- |
| Correctness | always | logic, edge cases, null/undefined, boundaries, concurrency, error handling — inward: is the new code right? | `axis-checklists.md` |
| Standards | always | conventions, naming, structure, Fowler code smells, non-behavioral quality | `axis-checklists.md` |
| Regression | always | callers, contracts, migrations, backward compatibility — outward: what could this break? | `axis-checklists.md` |
| Security | always (triage); deep pass only when a security surface is touched | injection, auth/authz, secrets, sensitive data, OWASP / STRIDE | `axis-checklists.md` |
| Spec | a spec source exists — PR description, commits, linked issue/ticket, or a path provided | missing or partial requirements, scope creep, a requirement implemented wrong | `axis-checklists.md` |
| Performance | diff touches hot paths, loops, queries, or allocations | N+1 queries, algorithmic complexity, resource leaks, missing pagination | `axis-checklists.md` |
| Tests | tests are present or expected for the change | coverage of new logic, edge-case tests, assertion quality | `axis-checklists.md` |
| Observability | change is operationally significant — services, error paths, external calls | logging, metrics, tracing | `axis-checklists.md` |

Every axis is a cheap triage first — does it apply, and how deep? — then a gated deep pass. Security is the most visible case of that rule, not an exception to it.

## Risk dial

Scale which axes fire and how deep the context work goes to the change's risk.

| Risk | Examples | Axes | Context depth |
| --- | --- | --- | --- |
| Trivial | docs, config, formatting, typo fixes | always-on axes at triage depth (Standards carries it) + Spec if a source exists | full file read only |
| Standard | feature work, refactors, test additions | all always-on + triggered conditionals | changed files + callers |
| Risky | auth, payments, DB schema, public API, concurrency | all applicable, deep passes | full data-flow tracing, history, convention sampling |

## Execution

Isolation is the mechanism that stops one axis from coloring another, so **run the axes as isolated sub-agent passes whenever this environment exposes a task or sub-agent tool** and the risk is not Trivial. This is required, not a preference — dispatch per `references/parallel-axes.md`, which bundles the axes into a few tasks (heavy independent axes each get a task; light axes share one) so isolation doesn't cost eight diff re-feeds.

**Capability floor.** Dispatch each isolated pass to a reasoning-capable agent whose tier matches the Risk dial — a small fast tier may cover a Standard read, but a Risky review needs a top reasoning tier, and Security, Correctness, and Regression never run on the cheapest / fastest tier. A search / recon-only helper is a poor fit for a judgment axis — prefer a general reasoning agent.

Fall back to **sequential inline** passes only when no task or sub-agent tool is exposed, or the risk is Trivial (dispatch overhead outweighs the gain). Inline gives best-effort isolation: reset focus to each axis's brief and write its findings under its heading before the next, and weigh the result accordingly.

If a dispatched axis fails or returns empty, re-run it — a silent drop must never read as "no findings".

## Severity

| Tag | Meaning | Action |
| --- | --- | --- |
| `[BLOCKER]` | security hole, data-loss risk, crash, correctness bug | blocking — fix before merge |
| `[MAJOR]` | logic error, missing edge case, architectural violation, missing tests | blocking — fix or justify |
| `[SUGGESTION]` | refactor, readability, optimization | non-blocking — recommended |
| `[NIT]` | style, naming preference, formatting | non-blocking — author's call |
| `[KUDOS]` | exemplary code, good pattern | recognition |

Assign severity **within each axis**. `[BLOCKER]` and `[MAJOR]` are blocking; the rest are non-blocking.

## Aggregation

**Re-check dispatched findings first.** Independently verify each dispatched finding against the code and its contract and re-severitize before assembling — dispatched severities are inputs, not final. This is within-axis validation against ground truth, not cross-axis re-judging: keep each axis's grouping intact, and a severity you overturn is also reason to lower that axis's confidence.

Copy the re-checked findings into the report unchanged, under that axis's heading. Build the findings table by grouping stably on (axis, severity), keeping every axis's rows distinct.

- **Completion criteria** — two gates, both required to keep one axis from masking another:
  1. Each active axis ran in its own isolated pass whenever a task or sub-agent tool was exposed; only the Trivial or no-sub-agent fallback runs axes inline.
  2. Every active axis appears as its own labeled group in the output, including axes that found nothing (which state "no findings").
- **Verdict** is the only value computed across axes: `REQUEST_CHANGES` if any axis produced a `[BLOCKER]` or `[MAJOR]`, otherwise `COMMENT` or `APPROVE`. Compute it last, from the assembled findings; it never changes an individual finding.
- **Confidence** — each axis scores itself 1-5, lowering its own score for the risk multipliers it owns (see Confidence adjustments); the overall confidence is the **minimum** across active axes. Name the axis that set it and why.

### Confidence adjustments

Each axis drops its own score by 1 (floor 1) for every multiplier it carries. Two axes dropping for the same broad multiplier is two independent reasons to distrust two reads, not double-counting:

- **Security** — auth / authz or otherwise security-sensitive logic.
- **Regression** — database migrations or schema changes.
- **Correctness** — complex concurrency or lock management.
- **Tests** — missing or inadequate coverage for the change.
- **Every active axis** — a large cross-cutting refactor, or an unfamiliar language / domain.

## Output

Use this skeleton for both modes. It is an index into the findings, not a restatement of them. Keep the verdict and findings table above the fold; blockers and majors are never collapsed. Secondary summary-only material — the per-file confidence table, strengths — goes in `<details>` on large reviews.

````markdown
## Code Review Summary

**Scope**: [what changed] · **Files**: [N files, +X/-Y] · **Confidence**: [min N/5 — the axis that set it, and why]

### Findings

| ID | Axis | Sev | Location | Summary |
| --- | --- | --- | --- | --- |
| B1 | Security | [BLOCKER] | path/to/file:42 | one line — full detail inline |
| M1 | Regression | [MAJOR] | path/to/other:15 | one line — full detail inline |

Axes with no findings are listed explicitly, e.g. "Correctness — no findings".

<details><summary>Per-file confidence</summary>

Only files whose confidence deviates from the overall — omit files that match it.

| File | Confidence | Notes |
| --- | --- | --- |
| path/to/file:42 | 2/5 | complex auth path |

</details>

<details><summary>Strengths</summary>

- `[KUDOS]` — exemplary section worth reinforcing.

</details>

### Verdict: APPROVE | REQUEST_CHANGES | COMMENT

[one-line justification]
````

For PR reviews, the inline-vs-summary strategy, GitHub comment formatting rules, the atomic-review pipeline, the AI attribution footer, and incremental re-review scoping live in `references/pr-workflow.md`.

## Feedback craft

- **Write it clearly.** Run the `/writing-clearly-and-concisely` skill and apply it to every finding, the summary, and PR comments — plain, tight, no filler.
- **Ask, don't assert.** "What happens when this input is empty?" invites reflection more than a flat claim.
- **Suggest, don't command.** "Consider a Map here for O(1) lookups" over "Use a Map." Offer alternatives as possibilities.

## References

- `references/axis-checklists.md` — per-axis deep checklists; load the sections for the active axes.
- `references/parallel-axes.md` — sub-agent dispatch, the self-contained brief template, bundling, and aggregation mechanics.
- `references/context-gathering.md` — the concrete caller / history / churn commands for the Gather-context step, scaled to the Risk dial.
- `references/pr-workflow.md` — GitHub PR pipeline: collect prior feedback, incremental re-review scoping, atomic review API, AI attribution footer, comment formatting.
- `references/language-patterns.md` — Python / TypeScript and cross-language bad/good examples, applied within Correctness, Standards, and Security.
