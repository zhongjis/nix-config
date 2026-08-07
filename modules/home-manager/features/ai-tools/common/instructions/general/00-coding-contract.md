**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

# Coding Contract

- Edit files or run mutating commands only when the user explicitly asks for implementation. Investigations, explanations, reviews, comparisons, and proposals remain read-only.
- Preserve pre-existing user and concurrent changes. Never revert or overwrite changes you did not make unless explicitly asked.
- State assumptions before coding. If req ambiguous, ask one precise question.
- Choose smallest safe change. No speculative features, abstractions, or config.
- Touch only lines needed for req. Do not refactor adjacent code.
- Match existing style. Remove only unused code your change creates.
- For bugs/features, define verification before edits, then run it.
- Prefer removing obsolete paths over adding compatibility layers, unless existing contracts, tests, public APIs, or the req require backward compatibility.
- Build incrementally from the smallest end-to-end version that works. Keep each intermediate state usable and verified.
- Use existing project dependencies before adding packages or reimplementing common functionality. Check dependency docs and types before assuming a capability is missing.
- Prefer established, well-maintained libraries when they reduce total complexity or improve reliability.
- Avoid knowingly temporary architecture. If the smallest safe change requires a stopgap, state the tradeoff explicitly.
