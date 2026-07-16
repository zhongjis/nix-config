# nix-config

Personal Nix flake that configures NixOS and nix-darwin machines and their user
environments through an auto-discovered module system.

## Language

### Machines & profiles

**Host**:
A named machine configuration under `hosts/<name>/` that composes an OS profile and a Home Manager profile.
_Avoid_: box, node, target

**System**:
The Nix platform double for a host, e.g. `x86_64-linux` or `aarch64-darwin`.
_Avoid_: arch, platform

**OS profile**:
A host's system-level configuration — NixOS on the framework, nix-darwin on the MacBook.
_Avoid_: system config, machine config

**Home Manager profile**:
A host's user-environment configuration, named `user@host` (e.g. `zshen@framework-16`).
_Avoid_: user config, dotfiles

**AI profile**:
The `aiProfile` value (`work` or `personal`) that tweaks prior AI-tooling behavior for a host.
_Avoid_: mode, environment

### Module taxonomy

**Namespace**:
One of the generated option roots — `myNixOS`, `myNixDarwin`, `myHomeManager` — under which a module exposes its `enable` toggle.
_Avoid_: prefix, scope

**Bundle**:
A module that enables a curated set of features together via `mkDefault`.
_Avoid_: preset, group, meta-module

**Feature**:
A single static capability — configuration or tooling — toggled by `my<Namespace>.<name>.enable`.
_Avoid_: option, package

**Service**:
A module that manages a running or background process (daemon or agent), exposed under the `.services.*` sub-namespace.
_Avoid_: daemon, background feature

### Boundary

**Private flake**:
The sibling `nix-config-private` repository consumed via the `nix-config-private` flake input; holds work and private configuration under the `zshen-private-flake.*` and `myPrivate.bundles.*` namespaces.
_Avoid_: secrets repo, work repo
