# Shell Tools

**Context:** `fd`, `rg`, and `ast-grep` are installed globally. Never fall back to POSIX `find`/`grep` when the modern tool is present.

## Relationship to CodeGraph

Use CodeGraph before shell search for indexed code structure: architecture,
code flow, symbol definitions, callers/callees, impact radius, routes,
components, and "how does X work?" questions.

Use shell tools for raw filesystem and text work: `fd` for paths/files,
`rg` for exact text/literals/config/docs, and `ast-grep` for syntax-shaped
patterns that regex cannot safely match.

Do not use `rg`/`Read` first to understand indexed code when CodeGraph is
available. Fall back to `rg` for literals, generated text, non-indexed files,
or details CodeGraph did not cover.

## Mandatory substitutions

**Before running `find` or `grep` in any bash command, STOP and rewrite using the table below.**

| POSIX command                         | Use instead            | Notes                    |
| ------------------------------------- | ---------------------- | ------------------------ |
| `find . -name '*.py'`                 | `fd -e py`             | Extension filter         |
| `find . -type d -name node_modules`   | `fd -t d node_modules` | Directory search         |
| `find . -name '*.py' -exec X {} \;`   | `fd -e py -x X`        | Batch exec               |
| `find . -name X -maxdepth 1`          | `fd X -d 1`            | Depth limit              |
| `grep -r foo .`                       | `rg foo`               | Recursive grep           |
| `grep -rn 'pattern' --include='*.ts'` | `rg 'pattern' -t ts`   | Type-scoped search       |
| `cat file \| grep pattern`            | `rg pattern file`      | Single-file search       |
| `ls \| grep pattern`                  | `fd pattern -d 1`      | Directory listing filter |

## ast-grep — specialist only

`ast-grep` is NOT a replacement for `rg`. `rg` remains the default for exact text search.

**Use `ast-grep` ONLY when regex cannot reliably match the structure you need:**

- Function calls with a specific argument shape (e.g., `foo($X, null, $$$)`)
- Decorated classes / annotated functions
- Nested AST patterns (e.g., `await` inside `try` inside async fn)
- Structural refactors that must preserve syntax shape

**Keep using `rg` for:** exact text matches, literals, config/docs, file-content grep, and fallback symbol search when CodeGraph is insufficient.

## Exceptions (use POSIX tools only when)

1. Target system genuinely lacks `fd`/`rg`/`ast-grep`. Verify first:

   ```bash
   command -v rg >/dev/null || grep -r pattern .
   ```

2. `find -empty`, `find -newer`, or complex boolean combinations `fd` cannot express. Note why in the command.
3. POSIX shell scripts being committed to repos without `fd`/`rg` as dependencies.

## Verification

If you catch yourself typing `find ` or `grep ` in a bash command, rewrite it first.

## Escalation

Load the matching skill when:

- `ast-grep` pattern needs more than a one-liner → load `ast-grep` skill (has `REFERENCE.md`)
- Two `fd`/`rg` attempts fail on flag combos (size, time, boolean, type filters) → load `fd` or `rg` skill instead of guessing again
