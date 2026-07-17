# Enterprise Codebase Strategy

**Context:** Enterprise codebases with established patterns, multiple contributors, and production dependencies. Changes have downstream impacts.

**Goal:** Minimize risk, maximize stability, respect existing architecture.

## Core Rules

Extends the Coding Contract for shared/production code:

1. **Read before writing.** Read 2-3 similar files first; match their naming, structure, error handling, and style — even if you'd do it differently.
2. **Never expand scope without approval.** No refactoring, restructuring, or dependency changes beyond the immediate task (see Approval Required).

## Format Matching

**Match the EXISTING format exactly, even if it's "wrong."**

- Match indentation (tabs/spaces/width), brace style, quote style, and line breaks manually.
- Formatting changes create noisy diffs → breaks blame, hides real changes, multiplies merge conflicts.
- **DO NOT run formatters** (`prettier`, `black`, `gofmt`, `rustfmt`, etc.) on existing files. Formatters are for new files only.
- **EXCEPTION:** If CI/pre-commit enforces formatting, comply — but only on files you modified, in an isolated commit.

## Approval Required (ALWAYS)

These changes are **never** self-authorized:

- Modify shared utilities or API contracts
- Change database schemas or migrations
- Update, add, or remove dependencies
- Refactor or restructure code
- Modify build configs, CI/CD, or infrastructure-as-code
- Alter environment variables or secrets references
- Add new patterns not already in the codebase

When requesting approval, state: current pattern, proposed change, why existing pattern doesn't work, impact, and risk.

## Security (BLOCKING)

- **NEVER** log secrets, tokens, keys, or PII.
- **NEVER** weaken authentication, input validation, or permission checks without security review.
- **NEVER** hardcode credentials or commit `.env` files.
- Use existing secret management and validation patterns exactly.

## Generated and Lock Files

- **Never hand-edit** generated code (`*.pb.go`, `*.generated.ts`), lock files, vendor dirs, or build artifacts.
- Modify the generator input, not the output. Let package managers update lock files.

## Verification (MANDATORY)

Before declaring any change complete:

1. Run available tests for modified code.
2. Run lint/typecheck if configured.
3. Ensure build passes.
4. If checks cannot be run, **state explicitly** what you couldn't verify and why.

> Unverified changes are labeled as unverified. Never imply confidence you don't have.

## When Uncertain

**When uncertain, ask. Never assume.** Read more code, or clarify scope or requirements before proceeding.
