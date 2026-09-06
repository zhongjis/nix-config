# Nix Environment Awareness

**Context:** This environment uses the Nix package manager. Prefer ephemeral or project-scoped execution over mutating the host. If asked to edit the user's personal Nix config, use `~/personal/nix-config`.

## Command Selection

- Use the project’s existing environment and package manager. Reuse an already-loaded environment. Otherwise, inspect `.envrc` when present and prefer the project’s approved direnv setup; use `nix develop` when no applicable direnv setup exists and the flake provides a suitable dev shell. Do not automatically authorize an untrusted `.envrc`.
- For ad-hoc execution, use `nix shell` for tools or commands and `nix run` for a package's default executable.
- Do not make persistent host changes unless the user explicitly requests them. Avoid global mutable installs; prefer ephemeral or project-scoped execution.

## Detailed Ad-hoc Guidance

For detailed Python, Node.js, and ad-hoc command selection, see the `nix` skill (ad-hoc execution reference).
