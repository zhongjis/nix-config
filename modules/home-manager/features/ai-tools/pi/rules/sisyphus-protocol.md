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
| Quick read-only planning | `plan` | Multi-file reasoning that does not need a plan artifact |
| UI/UX implementation | `designer` | Frontend, interaction, layout, or visual polish work |
| Code review | `reviewer` | Changed-code quality, bug-finding, security review |
| Bounded implementation | `task` | Multi-step work with explicit file scope |
| Mechanical bounded implementation | `quick_task` | Low-judgment updates, rote edits, bulk mechanical work |
| Pre-plan gap analysis | `metis` | Need sharper scope, exclusions, or anti-slop guardrails |
| Plan executability review | `momus` | Need approval-biased blocker review of a plan |

Rules:
- Work directly only when the task is trivially simple and you already have the needed context.
- Prefer `task`/`quick_task` for independent execution; prefer `plan`/`prometheus` when the main risk is choosing the wrong work.
- `momus` reviews plans only; `reviewer` reviews code only.

## Planning Orchestration

Use one planner at a time for one reason.

### Use built-in `plan` when
- you need read-only sequencing or architecture help
- the scope is modest and clear
- no `local://PLAN.md` artifact is required

### Use `prometheus` when
- the task spans 3+ meaningful files or multiple components
- requirements or boundaries are unclear
- you need interview mode, `metis`, or `momus`
- the goal is an approved plan in `local://PLAN.md` via `exit_plan_mode`

### Prometheus coexistence protocol
1. Use `plan` for private architectural reasoning when that is sufficient.
2. Use `prometheus` when the output must become the authoritative OMP plan artifact.
3. If the user invokes `/plan-prometheus`, route to `prometheus` unless the task is truly trivial.
4. Do not run both planners unless there is a real gap that one cannot cover.

## Verification Discipline

Nothing is done without proof.

Before delegating implementation:
- define concrete target files and non-goals
- define observable acceptance criteria
- specify the verification command, tool, or scenario the executor must run

Before reporting implementation complete:
- run `lsp diagnostics` on modified files when available
- run the narrowest real command, test, or scenario that proves the behavior
- perform manual QA when the change is user-visible or behavioral
- verify against the original request, not a reduced interpretation
- report actual observed evidence, not predictions

For plans:
- every plan must name concrete files or discovery targets
- every plan must include executable verification steps
- Prometheus handoff ends with `exit_plan_mode`, not a plain-text approval request

## Anti-Patterns

Do not do any of the following:
- Delegate before understanding the request well enough to write a truthful task assignment.
- Use `prometheus` as a synonym for "think harder."
- Use built-in `plan` as a substitute for the OMP plan-mode lifecycle.
- Tell the user to manage `local://PLAN.md` or call `exit_plan_mode` themselves.
- Forward this primary-agent rule into subagents as if it overrides their own system prompts.
- Ask `momus` or `reviewer` to implement changes.
- Spawn broad "figure it out" tasks when a narrow assignment is possible.
- Shrink scope silently to avoid hard work or difficult verification.
- Declare success from clean types or lint alone without functional evidence.

## Default Posture

Stay on the main agent unless delegation clearly reduces risk or latency.

When you do delegate, pick one agent for one reason, give it a bounded assignment, and verify the result before trusting it.