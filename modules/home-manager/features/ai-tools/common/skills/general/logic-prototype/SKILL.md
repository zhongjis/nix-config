---
name: logic-prototype
description: Validate business rules, state transitions, data shape, or API behavior with a throwaway terminal harness.
upstream: "https://github.com/mattpocock/skills/tree/main/skills/engineering/prototype"
---

# Logic Prototype

A logic prototype is **throwaway code that answers a question about behavior**. Use it to test business logic, state transitions, data models, or API shape before committing to production code.

For screens, visual layout, interaction design, or mockups, do not use this skill; use `impeccable` or `huashu-design`.

## Process

Follow [LOGIC.md](LOGIC.md) to build a tiny interactive terminal app that lets the user drive the state model by hand.

## Rules

1. **Throwaway from day one, clearly marked.** Put prototype code near the module it explores, and name it so readers know it is not production.
2. **One command to run.** Use the project's existing task runner.
3. **No persistence by default.** Keep state in memory unless persistence is the question.
4. **Skip polish.** No tests, no production error handling, no speculative abstractions.
5. **Surface the state.** After every action, print the full relevant state.
6. **Delete or absorb when done.** Keep the answer, not the harness.

## When done

Capture the question and answer somewhere durable (commit message, ADR, issue, or `NOTES.md` next to the prototype), then delete the throwaway harness or fold the validated logic into real code.
