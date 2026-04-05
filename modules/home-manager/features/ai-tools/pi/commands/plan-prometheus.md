---
name: plan-prometheus
description: Draft or refine an executable OMP plan through the Prometheus subagent
---

Use this when the user wants a concrete work plan, not just a quick architectural opinion.

User request:

$ARGUMENTS

Instructions for the current agent:

1. Decide whether the request actually needs a plan artifact.
   - If the task is trivial or already fully specified for direct execution, say so and continue without Prometheus.
   - Otherwise continue with the steps below.

2. Invoke `task(agent="prometheus", ...)` as a subagent.
   - Pass the user goal from `$ARGUMENTS`.
   - Include the active scope, constraints, non-goals, and any critical file paths already known.
   - Tell Prometheus whether this session is already in OMP plan mode.
   - Tell Prometheus to use `local://prometheus-draft.md` as scratch space when helpful, but to converge on the authoritative OMP plan artifact.

3. If not already in OMP plan mode:
   - Have Prometheus prepare a self-contained plan suitable for `local://PLAN.md`.
   - Have Prometheus use `ask` only for real ambiguities it cannot resolve by exploration.
   - Have Prometheus use `todo_write` for its planning workflow when useful.
   - When the plan is ready, have Prometheus present it through `exit_plan_mode`.

4. If already in OMP plan mode:
   - Have Prometheus update or rewrite the active plan in `local://PLAN.md`.
   - `local://prometheus-draft.md` may be used as temporary working space before merging back into `local://PLAN.md`.
   - When the updated plan is ready for approval, have Prometheus call `exit_plan_mode`.

5. Prometheus may delegate focused planning or discovery work with `task(agent="...", ...)`, but only when that improves plan quality. Keep assignments narrow and relevant.

6. Do not ask the user to manually run planning tools or manually exit plan mode. The agent must drive the Prometheus lifecycle end to end.