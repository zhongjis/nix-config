---
name: brainstorming
description: >
  Use when user explicitly asks to brainstorm, explore options, compare approaches,
  think through a problem, or shape an idea before implementation. Prefer this
  skill when request is about choosing direction or refining solution space, not
  executing a clear bounded change.
upstream: "https://github.com/obra/superpowers/tree/main/skills/brainstorming"
---

# Brainstorming Ideas Into Designs

Turn vague ideas into clear directions through short collaborative dialogue.

Start by understanding project or problem context. Ask one clarifying question at a time. Once intent and constraints are clear, propose a few approaches, recommend one, then summarize a clear direction before implementation.

## Hard Gate

Do not write code, scaffold projects, or take implementation action during brainstorming.
Stop at clear recommended direction.

## Workflow

1. **Explore context** — for existing codebases, check relevant files, docs, existing patterns, and constraints first.
2. **Assess scope** — if request is too broad, decompose it into smaller sub-projects or phases before going deeper.
3. **Ask clarifying questions** — one at a time. Focus on purpose, constraints, risks, and success criteria.
4. **Propose approaches** — give 2-3 options with trade-offs. Lead with your recommendation.
5. **Present design direction** — explain architecture, components, data flow, edge cases, and testing approach at a level matched to complexity.
6. **Validate incrementally** — check whether each section looks right before moving on.
7. **Stop after alignment** — summarize recommended direction and wait for explicit request before planning or implementation.

## Brainstorming Rules

- **One question per message** — do not dump a questionnaire.
- **Multiple choice preferred** — easier for users when possible.
- **YAGNI** — cut extras that do not serve stated goals.
- **Explore alternatives** — do not jump to first idea.
- **Follow existing codebase patterns** when brainstorming changes in an existing repo.
- **Stay scoped** — no unrelated refactors.

## Design Guidance

### Understanding problem

- Check current project state before proposing changes when working in an existing codebase.
- If request bundles multiple independent systems, call that out early and help choose first slice.
- Make assumptions explicit.
- Clarify anything ambiguous before settling on direction.

### Comparing approaches

For each approach, cover:

- what it is
- why it fits or does not fit
- major trade-offs
- your recommendation

### Presenting design

Cover only what matters for request complexity, typically:

- architecture / structure
- main components or modules
- data flow and interfaces
- error handling / edge cases
- testing / verification strategy

Prefer small, well-bounded units with clear responsibilities and interfaces.

## Out of Scope

This skill does **not** include:

- visual companion or browser-driven brainstorming
- mandatory spec file creation or commits
- automatic handoff to another skill
- implementation work
