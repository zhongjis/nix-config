# Parallel Axes

How to run review axes as isolated sub-agent passes — the *how*. `SKILL.md` § Execution owns the *when* (required whenever the environment exposes a task or sub-agent tool and the risk is not Trivial); if no such tool exists, ignore this file and run the axes sequentially inline.

## What to dispatch (fan-out control)

Spawning one sub-agent per axis re-feeds the diff to eight tasks and wastes context. Group instead:

- **Heavy, independent axes → one task each:** Security, Regression, Performance. Each does deep, mostly separate work.
- **Light axes → one bundled task:** Correctness + Standards, plus any active conditional axis that is cheap (Tests, Observability).
- **Spec** rides with the bundle, unless the spec is large — then give it its own task.

Scale granularity to risk: at Standard risk, one heavy task plus one bundle is often enough; reserve the full split for Risky diffs.

## Self-contained brief (every task carries this)

A dispatched task shares none of the main context, so its brief must stand alone. Include, verbatim:

1. **Diff access** — the exact diff command (`git diff <base>...HEAD`) and the commit list, or the diff contents.
2. **Foundation brief** — the behavior delta and the axis triage from step 3 of the process.
3. **Axis assignment** — which axis or axes this task owns, with the matching section(s) of `axis-checklists.md` pasted in full; the task cannot open files the main agent read.
4. **Report contract** — "Report findings for your assigned axis only. Tag each with the axis name, a severity (`[BLOCKER]` / `[MAJOR]` / `[SUGGESTION]` / `[NIT]` / `[KUDOS]`), and a file:line. Quote the code or spec line for each. Score this axis's confidence 1-5, dropping it by 1 for each risk multiplier this axis owns (SKILL.md § Confidence adjustments). If you find nothing, say so explicitly. Under 400 words per axis."

The same brief structure feeds a sequential inline pass — that shared shape is what keeps the two execution modes producing identical review content.

## Aggregation

When the tasks return, assemble them per the **Aggregation** rules in `SKILL.md`: copy each axis's findings in unchanged under its heading, group the table stably by (axis, severity) with every axis's rows kept distinct, list every dispatched axis including the ones that found nothing, then compute the verdict and the minimum confidence last.

Isolation is the point: because each task ran in its own context, no axis could see or be colored by another. That separation is already enforced by the dispatch — carry it through into the report rather than re-judging across axes. Carrying separation through is not the same as trusting dispatched severities verbatim: the orchestrator still validates each finding within its axis (SKILL.md § Aggregation).
