# Shell Tools

**Context:** `fd`, `rg`, and `ast-grep` are installed globally. For local interactive discovery, use `fd`, `rg`, and `ast-grep` by default. Use POSIX `find`/`grep` only under the exceptions below.

## Relationship to CodeGraph

Use CodeGraph first for questions about indexed code structure: architecture,
code flow, symbol definitions, callers/callees, impact radius, routes,
components, and "how does X work?" questions.

For known targets, use `read` for a known path and `rg` for exact text, literals, config, or docs.
Use `fd` for paths/files and `ast-grep` for syntax-shaped patterns that regex cannot safely match.

Use CodeGraph evidence for indexed architecture and code flow rather than reconstructing it with `rg` or `read`. Fall back to direct tools when CodeGraph is unavailable, files are generated or non-indexed, or graph evidence is incomplete.

## POSIX fallbacks

For local interactive discovery, use `fd`, `rg`, and `ast-grep` first. If falling back because a modern tool is missing, confirm its absence with `command -v` before using POSIX `find` or `grep`. If the modern tool cannot preserve the required semantics, explain the limitation before using a POSIX alternative.

## Detailed command guidance

When command syntax or semantics are uncertain, consult the matching `fd`, `rg`, or `ast-grep` skill for conversions, ignore/hidden behavior, search options, and advanced patterns.
