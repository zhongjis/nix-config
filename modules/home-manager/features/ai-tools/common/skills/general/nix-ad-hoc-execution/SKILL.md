---
name: nix-ad-hoc-execution
description: Chooses the right ad-hoc execution path in this Nix environment. Use when a command is missing, when you need a one-off CLI, or when Python/Node work needs temporary dependencies without mutating the host.
---

# Nix Ad-hoc Execution

Use this skill to choose the narrowest temporary execution path without polluting the host.

## Selection Order

1. **Project environment first**
   - If the repo has `flake.nix`, prefer `nix develop` for project work.
   - If the project already uses a local package manager workflow, use that instead of creating a parallel one.

2. **Choose the narrowest tool**
   - Need the repo's development environment -> `nix develop`
   - Need one package's default executable -> `nix run`
   - Need ad-hoc tools, arbitrary commands, shell pipelines, or multiple packages -> `nix shell`
   - Need temporary Python libraries -> `uv run --with ...`; otherwise use `nix shell` with a Python environment
   - Need a Node.js tool in project context -> `npx ...`; if Node.js is missing, use `nix shell nixpkgs#nodejs -c npx ...`

## Quick Examples

```bash
nix develop
nix run nixpkgs#hello
nix shell nixpkgs#jq nixpkgs#yq -c "jq ... | yq ..."
uv run --with requests python3 script.py
npx tsx script.ts
```

## Guardrails

- Do not mutate the host environment unless the user explicitly asks for a persistent setup change.
- Prefer project-scoped or ephemeral execution over system-wide changes.
- Avoid `pip install`, `pip install --user`, `npm install -g`, `sudo npm install -g`, and similar global mutable installs as the default answer.

## Related Skills

- `nix` - broader Nix command and evaluation patterns
- `nix-flakes` - flake-based environments and workflows
- `nh` - NixOS / Home Manager switching and maintenance
- `python` - Python project structure, typing, and testing
- `uv` - uv project and dependency workflows
- `pnpm` / `bun` - project-specific Node.js package manager workflows
