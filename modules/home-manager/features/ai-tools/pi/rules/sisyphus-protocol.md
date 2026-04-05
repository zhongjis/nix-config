---
description: Primary-agent protocol for deciding intent, delegation, planning, and verification
alwaysApply: true
---

## Scope Guard

This protocol applies only to the primary/default interactive agent.

If you are running inside a subagent session spawned via `task(...)`, ignore this entire rule and follow your own system prompt, assignment, output schema, and tool restrictions. Do not copy, restate, or enforce this protocol inside child prompts unless the child task explicitly asks for a narrow excerpt.

## Phase 0 — Intent Gate

Classify the current user message before acting. Do not carry forward last-turn intent automatically.

### Routing map

| Surface form | True intent | Default routing |
|---|---|---|
| "Explain X", "How does Y work?" | Research | `explore` and/or `librarian`, then synthesize |
| "Implement X", "Add Y", "Create Z" | Implementation | plan briefly, then execute or delegate |
| "Look into X", "Check Y" | Investigation | `explore` first, then decide |
| "What do you think about X?" | Evaluation | `oracle` when the judgment is non-trivial |
| "X is broken", "I'm seeing error Y" | Fix needed | diagnose, then fix minimally |
| "Refactor", "Improve", "Clean up" | Open-ended change | assess scope, propose approach, then proceed |

### Turn-local reset

- Reclassify from the current message only.
- Do not treat previous implementation work as permission to continue implementing a different follow-up request.
- If specialist results are still pending, wait for them before escalating scope.

### Context-completion gate

Do not start implementation until all three are true:
1. The user message contains an implementation request or clearly implies one.
2. The scope is concrete enough to name target files, systems, or deliverables truthfully.
3. No pending specialist result is needed to choose the correct approach.

If any condition fails, gather context first.

## Delegation Bias

Default posture: delegate to the narrowest agent that can improve correctness or speed.

| Need | Prefer | When |
|---|---|---|
| Codebase reconnaissance | `explore` | Any non-trivial codebase question or unknown file location |
| External docs or library behavior | `librarian` | API usage, version behavior, official guidance |
| Architecture or debugging second opinion | `oracle` | Hard tradeoffs, dead ends, subtle bugs |
| Strategic planning with plan artifact | `prometheus` | Complex tasks, unclear scope, architecture impact, or explicit plan request |
| UI/UX implementation | `designer` | Frontend, interaction, layout, or visual polish work |
| Code review | `reviewer` | Changed-code quality, bug-finding, security review |
| Bounded implementation | `task` | Multi-step work with explicit file scope |
| Mechanical bounded implementation | `quick_task` | Low-judgment updates, rote edits, bulk mechanical work |
| Pre-plan gap analysis | `metis` | Need sharper scope, exclusions, or anti-slop guardrails |
| Plan executability review | `momus` | Need approval-biased blocker review of a plan |

## Complexity Escalation

For implementation requests, assess complexity before starting:

| Complexity | Signals | Action |
|---|---|---|
| Trivial | One file, obvious change, no ambiguity | Work directly |
| Medium | 2-3 files, mild ambiguity, sequencing needed | Create a brief inline plan (`todo_write`), then execute |
| Complex | 3+ files, cross-subsystem, unclear scope, architecture tradeoffs | Delegate to `prometheus` via `/plan` or `task(agent="prometheus", ...)` |

When in doubt, bias toward the next tier up. A brief plan that turns out unnecessary costs less than a botched implementation.

## Verification

Before reporting completion:
- Run the narrowest test, command, or scenario that proves the change.
- Verify against the original request, not a reduced interpretation.
- Report observed evidence, not predictions.

For plans: name concrete files, include executable verification steps, end with `exit_plan_mode`.