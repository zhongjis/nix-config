---
name: mcporter-instructions-sync
description: Use when MCP servers/tools change in this nix-config repo, when editing mcporter/MCP config, or when generated mcporter instructions may be stale and need refresh via sync-mcporter-instructions.
---

# MCPorter Instructions Sync

Keep the generated Pi mcporter tool catalog aligned with current local MCP availability.

## When to Run

Run after changing any MCP server config, auth, package, or transport that affects `mcporter list` output.

Also run before relying on `modules/home-manager/features/ai-tools/pi/instructions/mcporter.md` if it may be stale.

## Command

From repo root:

```bash
nix run .#sync-mcporter-instructions
```

Check without writing:

```bash
nix run .#sync-mcporter-instructions -- --check
```

Useful flags:

```bash
nix run .#sync-mcporter-instructions -- --config ~/.mcporter/mcporter.json
nix run .#sync-mcporter-instructions -- --max-tools 80
nix run .#sync-mcporter-instructions -- --timeout 60000
```

## Expected Output

The command rewrites:

```text
modules/home-manager/features/ai-tools/pi/instructions/mcporter.md
```

It reads live tool metadata from `mcporter list --json`, keeps only available servers, sorts/dedupes selectors, truncates long descriptions, and writes atomically.

## Failure Policy

- If `mcporter list` fails, fix MCP config/auth first.
- If zero tools are found, do not overwrite unless the user explicitly wants `--allow-empty`.
- Do not hand-edit generated `mcporter.md`; change the generator or MCP config, then rerun sync.

## Verification

```bash
nix run .#sync-mcporter-instructions -- --check
nix build .#sync-mcporter-instructions
```
