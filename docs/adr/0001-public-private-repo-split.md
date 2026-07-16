# 0001 — Public/private repository split

Status: accepted

This repository is public, so all work-related and private configuration — work
modules and sops secrets — lives in a separate private repository,
`nix-config-private`, consumed here through the `nix-config-private` flake input
over SSH (`flake.nix`) and referenced under the `zshen-private-flake.*` and
`myPrivate.bundles.*` namespaces. We chose a hard two-repo boundary over a single
repo with encrypted secrets so the configuration can stay open-source without ever
exposing work internals.

## Consequences

- `nix flake check` and builds require SSH access to the private repo; failures may originate there.
- Changing shared module APIs, option names, or overlay outputs can break the private repo — check it before such changes.
- No secrets, work-internal names, or private-repo content may be inlined into this public repo.
