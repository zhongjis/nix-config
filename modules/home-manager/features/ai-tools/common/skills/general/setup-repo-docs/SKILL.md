---
name: setup-repo-docs
description: Set up or migrate a repository's documentation into a purpose-led structure that works with existing agent skills.
disable-model-invocation: true
---

# Set Up Repository Docs

Build a durable documentation home without creating competing sources of truth. This is an explicit setup or migration workflow, not an ongoing writing assistant.

## Target structure

```text
CONTEXT.md                    # Canonical domain language; create lazily
CONTEXT-MAP.md                # Optional index for multiple bounded contexts
docs/
├── README.md                 # Map, authority model, and declared canonical paths
├── ideas/                    # Non-binding exploration; Status: idea
├── specs/                    # Draft, planned, or shipped behavior/contracts
├── adr/                      # Append-only architecture decision records
├── guides/                   # Task-oriented instructions
├── references/               # External, stable, citable material only
└── rules/                    # Locked execution policy imported by root AGENTS.md
```

Declare every bucket in `docs/README.md`, but create bucket directories only when they contain a document. Use lowercase kebab-case paths. Name ADRs `NNNN-short-decision-title.md`.

Canonical bucket paths are `docs/ideas/`, `docs/specs/`, `docs/adr/`, `docs/guides/`, `docs/references/`, and `docs/rules/`. Setup is idempotent: a second run against a complete structure proposes no changes.

## Companion conventions

Reuse established artifacts rather than duplicating them:

- `domain-modeling` owns domain-language discovery and writes `CONTEXT.md`, optional `CONTEXT-MAP.md`, and ADR substance. Adopt existing files. Create them only when resolved terms or decisions exist.
- Use the domain-modeling ADR test: record a choice only when it is hard to reverse, surprising without context, and the result of a real trade-off.
- `agents-md` owns execution-contract content in `AGENTS.md`. Preserve that content; update only imports or path references required by the docs setup.
- Link `CONTEXT.md`, `CONTEXT-MAP.md`, and `docs/adr/` from `docs/README.md` when present.

`CONTEXT.md` is authoritative for vocabulary, not system behavior. Behavioral conflicts resolve in this order: rules → ADRs → shipped specs → guides → ideas. References provide evidence, never policy.

## Lifecycle rules

Use statuses `idea`, `draft`, `planned`, `shipped`, `superseded`, and `retired`.

- Every idea uses exact `Status: idea`; ideas are non-binding.
- Specs use `draft`, `planned`, `shipped`, `superseded`, or `retired` as appropriate.
- Add `Owner` and `Last reviewed` when ownership or freshness matters.
- ADR history is append-only. Supersede through a new ADR plus reciprocal `Supersedes` and `Superseded by` links.
- A path under `docs/rules/` is locked once adopted: never move or rename it. Root `AGENTS.md` imports applicable rules.
- Keep retired or superseded docs at meaningful paths; do not create an archive bucket.

## Setup workflow

### 1. Discover

Read root and applicable child `AGENTS.md` files, existing canonical docs, `CONTEXT.md`, `CONTEXT-MAP.md`, ADRs, indexes, scripts, and inbound links. Inventory each document by purpose, authority, status, owner, freshness, and path constraints.

Complete when every existing document and inbound reference is accounted for, with mixed or ambiguous documents flagged instead of guessed.

### 2. Design

Map clear documents to the target structure. Preserve established canonical files when moving them would create competing truth or break locked paths. Propose splits for mixed-purpose documents; leave unresolved items in place.

Write a proposed `docs/README.md` containing:

- bucket definitions and exclusions;
- links to canonical docs inside and outside `docs/`;
- `CONTEXT.md`/`CONTEXT-MAP.md` and ADR locations when present;
- lifecycle statuses and naming rules;
- behavioral authority order;
- unresolved migration decisions.

Complete when every proposed move has a purpose, destination, inbound-reference plan, and rollback-safe migration step.

### 3. Choose mode

- **Audit mode:** report proposed setup only; do not mutate files.
- **Apply mode:** proceed only after explicit user authorization for the proposed changes.

Complete when mode and authorization state are explicit.

### 4. Apply atomically

Create only needed directories and documents. Move only unambiguous content. Update `docs/README.md`, Markdown links, indexes, scripts, and `AGENTS.md` imports in the same change set. Preserve rule paths and ADR history.

Complete when no active reference points to an obsolete path and no subject has competing canonical documents.

### 5. Verify idempotency

Check all links, indexes, scripts, rule imports, canonical paths, metadata, and companion artifacts. Re-run the setup analysis against resulting tree.

Report each verification dimension separately as pass, absent/not applicable, or unverified; do not omit scripts or metadata merely because no corresponding files were supplied.

Complete when a second run proposes no structural changes; remaining output contains only explicitly unresolved documents or optional content work.

## Report

State mode, authorization, canonical sources inspected, proposed or applied paths, companion artifacts adopted, lifecycle changes, repaired references, verification evidence, idempotency result, and unresolved decisions.
