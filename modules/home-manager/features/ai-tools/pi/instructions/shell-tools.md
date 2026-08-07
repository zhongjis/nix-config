# Shell Tools

**Context:** `fd`, `rg`, and `ast-grep` are installed globally. For local interactive discovery, use `fd`, `rg`, and `ast-grep` by default. Use POSIX `find`/`grep` only under the exceptions below.

## Relationship to CodeGraph

Use CodeGraph first for questions about indexed code structure: architecture,
code flow, symbol definitions, callers/callees, impact radius, routes,
components, and "how does X work?" questions.

For known targets, use `read` for a known path and `rg` for exact text, literals, config, or docs.
Use `fd` for paths/files and `ast-grep` for syntax-shaped patterns that regex cannot safely match.

Do not reconstruct indexed architecture or code flow with `rg` or `read` when CodeGraph is available.
Fall back to direct tools for generated or non-indexed files, or details CodeGraph did not cover.

## Detailed command guidance

Detailed command conversions, ignore/hidden semantics, exact-name/depth searches, and advanced patterns or options live in the matching `fd`, `rg`, and `ast-grep` skills. Load the relevant skill when those details are needed.

## Exceptions (use POSIX tools only when)

1. Target environment lacks the modern tool. Check availability with `command -v` before using the POSIX fallback.
2. `find -empty`, `find -newer`, or complex boolean combinations `fd` cannot express. Note why in the command.
3. POSIX shell scripts being committed to repos without `fd`/`rg` as dependencies.
4. Exact requested behavior cannot be preserved with the available modern tool or options. State the semantic difference.

## Verification

Before using `find` or `grep` for local interactive discovery, confirm an exception applies; otherwise use the modern tool.

## Escalation

Load the matching skill when:

- `ast-grep` pattern needs more than a one-liner → load `ast-grep` skill (has `REFERENCE.md`)
- Two `fd`/`rg` attempts fail on flag combos (size, time, boolean, type filters) → load `fd` or `rg` skill instead of guessing again
