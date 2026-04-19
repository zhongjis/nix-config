---
name: brainstorming
description: >
  Use when user explicitly asks to brainstorm, explore options, compare approaches,
  think through a software or system design problem, or shape an idea before
  implementation. Prefer this skill when request is about choosing direction or
  refining solution space, not executing a clear bounded change.
adaptedFrom:
  - "https://github.com/obra/superpowers/tree/main/skills/brainstorming"
---

# Brainstorming Ideas Into Designs

Turn vague software ideas into clear directions through short collaborative dialogue.

Start by understanding project or problem context. Ask one clarifying question at a time, starting with what matters most. Once intent and constraints are clear, compare a few viable approaches, recommend one, then summarize a clear direction before implementation.

## Hard Gate

Do not write code, scaffold projects, or take implementation action during brainstorming.
Stop at clear recommended direction.

## Workflow

1. **Explore context** — for existing codebases, check relevant files, docs, existing patterns, and constraints first. Do not ask questions that can be answered quickly from the repo or available tools.
2. **Assess scope** — if request is too broad, decompose it into smaller sub-projects or phases before going deeper.
3. **Ask clarifying questions** — one at a time. Ask highest-uncertainty questions first. Usually establish scope boundaries, correctness or consistency requirements, success criteria, scale or performance assumptions, and team or operational constraints.
4. **Propose approaches** — give 2-4 options when useful, including at least one conservative or boring option. Compare options before converging on one recommendation.
5. **Present design direction** — explain architecture, components, data flow, interfaces, edge cases, testing, and reversibility or migration path only at the level needed for this request.
6. **Stress-test recommendation** — name key assumptions, strongest alternative, main risk, and what would make the recommendation wrong or worth revisiting.
7. **Validate incrementally** — check whether each major section looks right before moving on.
8. **Stop after alignment** — summarize recommended direction, rejected alternatives, assumptions to watch, and cheapest next validation step if uncertainty remains. Wait for explicit request before planning or implementation.

## Brainstorming Rules

- **One question per message** — do not dump a questionnaire.
- **Multiple choice preferred** — easier for users when possible.
- **Mark a recommended default** — when giving options and you have a clear view, make that visible.
- **Ask in uncertainty order** — resolve biggest unknowns before details.
- **Look up obvious answers first** — do not ask what existing files or tools can tell you.
- **YAGNI** — cut extras that do not serve stated goals.
- **Explore alternatives** — do not jump to first idea; include at least one boring option when it sharpens the decision.
- **Make assumptions explicit** — distinguish stated constraints from inferred ones.
- **Follow existing codebase patterns** when brainstorming changes in an existing repo.
- **Stay scoped** — no unrelated refactors.

## Design Guidance

### Understanding problem

- Check current project state before proposing changes when working in an existing codebase.
- If request bundles multiple independent systems, call that out early and help choose first slice.
- Establish what is in scope and out of scope before designing details.
- Clarify correctness, consistency, security, or reliability boundaries early when they shape the design.
- Clarify success criteria, scale, and operational constraints before settling on direction.
- Make assumptions explicit.
- Clarify anything ambiguous before settling on direction.

### Comparing approaches

For each approach, cover:

- what it is
- why it fits or does not fit current constraints and existing patterns
- main downside or likely failure mode
- implementation and operational complexity
- reversibility or migration cost
- trigger that would make another option better
- your recommendation after comparison

### Presenting design

Cover only what matters for request complexity, typically:

- architecture / structure
- main components or modules
- data flow and interfaces
- error handling / edge cases
- testing / verification strategy
- migration / rollout shape when it affects the decision

Prefer small, well-bounded units with clear responsibilities and interfaces.

### Completion Criteria

Brainstorming is complete when:

- problem is bounded enough to implement later
- alternatives were compared, not hand-waved
- main assumptions and risks are named
- recommended direction is clear and justified
- next validation step is clear if uncertainty remains
