# Documentation

Map, authority model, and canonical paths for this repository's docs.

## Authority model

Behavioral conflicts resolve in this order:

1. `docs/rules/` — locked execution policy
2. `docs/adr/` — architecture decision records (append-only)
3. `docs/specs/` — shipped specs
4. `docs/guides/` — task-oriented instructions
5. `docs/ideas/` — non-binding exploration

`docs/references/` provides evidence only, never policy.

`CONTEXT.md` (when present) is authoritative for vocabulary, not system behavior.

## Buckets

| Path              | Purpose                                                    |
| ----------------- | ---------------------------------------------------------- |
| `docs/ideas/`     | Non-binding exploration; `Status: idea`.                   |
| `docs/specs/`     | Draft, planned, shipped, superseded, or retired behavior.  |
| `docs/adr/`       | Architecture decision records; append-only.                |
| `docs/guides/`    | Task-oriented instructions.                                |
| `docs/references/`| External, stable, citable material only.                   |
| `docs/rules/`     | Locked execution policy imported by root `AGENTS.md`.      |

Paths under `docs/rules/` are locked once adopted: never moved or renamed.
ADR history is append-only; supersede via a new ADR with reciprocal links.

## Guides

- [Local models](guides/local-models.md) — install, manage, and run local GGUF models.

## Related

- Root `AGENTS.md` — execution contract for this repo.
- [`CONTEXT.md`](../CONTEXT.md) — canonical domain language for this repo.
- Decisions — [ADR 0001: Public/private repository split](adr/0001-public-private-repo-split.md).
