# Agent Guidelines for nix-config

This document provides guidelines for AI coding agents working in this Nix-based configuration repository. The codebase manages NixOS and Darwin system configurations using Nix flakes and Home Manager.

## Project Overview

- **Language**: Primarily Nix with some shell scripts
- **Purpose**: Personal NixOS and Darwin system configuration management
- **Structure**: Flake-based Nix configuration with modular organization
- **Package Manager**: Nix with flakes enabled
- **Version Control**: [Jujutsu (jj)](https://github.com/jj-vcs/jj) over Git — use `jj` commands, not `git`
- **Systems**: x86_64-linux, aarch64-darwin (and variants)

## Build, Test, and Lint Commands

### System Management

**Build/Switch System Configuration:**
```bash
# NixOS (Linux)
nh os switch .

# Darwin (macOS)
nh darwin switch .
# or
darwin-rebuild switch --flake .#mac-m1-max
```

**Build Specific Packages:**
```bash
# Build neovim package
nix build .#neovim

# Build helium package (Linux only)
nix build .#helium
```

**Development Environments:**
```bash
# Enter Node.js 22 development shell
nix develop .#nodejs22

# Enter Java 8 development shell
nix develop .#java8
```

### Testing

```bash
# Check flake for errors
nix flake check
```

### Formatting and Linting

No standalone commands are configured, but formatters/linters are integrated in neovim:

- **Nix**: `alejandra` (formatter)
- **JavaScript/TypeScript/YAML/Markdown/CSS/JSON**: `prettierd` (formatter)
- **Python**: `black` (formatter)
- **Java**: `google-java-format` (formatter)
- **Markdown**: `markdownlint` (linter)
- **Terraform**: `tflint`, `tfsec` (linters)

### Update Commands

```bash
# Update specific input
nix run github:zhongjis/nix-update-input

# Search nixpkgs
nh search <query>

# Update Hyprland inputs
./scripts/update-hyprland-inputs.sh

# Update Homebrew inputs
./scripts/update-homebrew-inputs.sh

# Update NixOS inputs
./scripts/update-nixos-inputs.sh
```

### Secret Management

```bash
# View secrets
nix run nixpkgs#sops -- secrets.yaml
```

## Code Style Guidelines

### Nix Language

**Indentation and Formatting:**
- Use **2 spaces** for indentation (never tabs)
- Always include **trailing commas** in lists and attribute sets
- No strict line length limit, but break naturally for readability
- Use `#` for single-line comments
- Use `/* */` for multi-line comments, often with language hints like `/* bash */`, `/* json */`

**Naming Conventions:**
- Variables and functions: `camelCase` (e.g., `myLib`, `currentSystemName`, `fontSize`)
- Attribute names: `camelCase` (e.g., `enableZshIntegration`, `baseIndex`)
- File names: `kebab-case` for directories (e.g., `home-manager`, `multi-lang-input-layout`)
- Module files: descriptive names with `.nix` extension

**Import Style:**
- Use **relative path imports** in lists
- Format: `imports = [ ../../modules/shared ../../modules/nixos ./hardware-configuration.nix ];`
- No absolute imports; paths are relative to the file location

**Structure Patterns:**
```nix
{
  pkgs,
  lib,
  config,
  ...
}: let
  # Local variables and helper functions here
in {
  # Configuration attributes here
  imports = [
    ./some-module.nix
    ../shared/another-module.nix
  ];
  
  # Attributes with trailing commas
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "username";
        email = "email@example.com";
      };
    };
  };
}
```

**Attribute Sets:**
- Use `let ... in` for local variables
- Put `imports` at the top of attribute sets
- Group related configuration together
- Use `mkDefault`, `mkOrder`, `mkMerge` from `lib` for option precedence

**Comments:**
- Add TODO comments for future work
- Explain non-obvious configuration decisions
- Document hardware-specific settings
- Use language hints in multi-line comments for embedded code

**Error Handling:**
- Rely on Nix's evaluation errors (no try/catch in Nix)
- Use assertions and warnings for configuration validation

### Shell Scripts

**Formatting:**
- Use **2 spaces** for indentation
- Follow standard bash conventions
- Add descriptive comments for non-obvious logic

**Style:**
- Keep scripts simple and focused
- Use basic conditional checks with `if`/`else`
- No advanced error handling patterns required

## File Organization

```
nix-config/
├── flake.nix              # Main flake definition
├── hosts/                 # System-specific configurations
│   ├── framework-16/      # NixOS host
│   └── mac-m1-max/        # Darwin host
├── modules/               # Reusable modules
│   ├── shared/            # Shared between NixOS/Darwin
│   ├── nixos/             # NixOS-specific modules
│   └── darwin/            # Darwin-specific modules
├── lib/                   # Utility functions and helpers
├── overlays/              # Package overrides and modifications
├── packages/              # Custom package derivations
├── templates/             # Flake templates for dev environments
├── secrets/               # Encrypted secrets (sops-nix)
└── scripts/               # Maintenance and update scripts
```

## Module Guidelines

**Creating New Modules:**
1. Place in appropriate subdirectory: `modules/shared/`, `modules/nixos/`, or `modules/darwin/`
2. Use relative imports
3. Follow the standard module structure with function arguments
4. Group related functionality together
5. Use `enable` options for optional features

**Home Manager Modules:**
- Location: `modules/shared/home-manager/features/`
- Each feature should be self-contained
- Use `programs.*` or `home.*` namespaces
- Configure shell aliases alongside program config

**System Modules:**
- Location: `modules/nixos/` or `modules/darwin/`
- Separate concerns into bundles (e.g., `bundles/general-desktop.nix`, `bundles/developer.nix`)
- Use custom options under `myNixOS.*` or `myDarwin.*` namespaces

## Important Patterns

**Using `lib` Functions:**
```nix
lib.mkDefault value           # Set default that can be overridden
lib.mkForce value             # Force a value, overriding others
lib.mkOrder priority value    # Set priority explicitly
lib.mkMerge [ {...} {...} ]   # Merge multiple attribute sets
lib.mkIf condition {...}      # Conditional configuration
```

**Special Arguments:**
- `pkgs`: Package set with overlays applied
- `lib`: Nixpkgs library functions
- `config`: Current configuration state
- `inputs`: Flake inputs
- `currentSystem`: Current system architecture
- `currentSystemName`: Host name
- `currentSystemUser`: Primary user
- `isDarwin`: Boolean for Darwin vs NixOS

**Overlays:**
- Location: `overlays/default.nix`
- Modifications go in `modifications` overlay
- Stable packages in `stable-packages` overlay
- Use for package overrides and custom builds

## Secret Management

- Uses `sops-nix` for encrypted secrets
- Age key location: `~/.config/sops/age/keys.txt`
- Secrets file: `secrets.yaml`
- Configuration: `.sops.yaml`
- Edit secrets with: `nix run nixpkgs#sops -- secrets.yaml`

## Common Pitfalls

1. **Forgetting trailing commas**: Always include them in Nix lists/sets
2. **Using absolute imports**: Use relative paths instead
3. **Not checking flake**: Run `nix flake check` before committing
4. **Mixing tabs and spaces**: Always use 2 spaces
5. **Hardcoding system**: Use `currentSystem` or `system` arguments
6. **Missing enable options**: Provide `enable` flags for optional features

## Development Workflow

1. Make changes to relevant `.nix` files
2. Test locally with `nh os switch .` or `nh darwin switch .`
3. Check for errors with `nix flake check`
4. Review changes with `jj log` and `jj diff`
5. Describe changes with `jj describe -m "message"`
6. Create new change with `jj new` after describing
7. Push with `jj git push`

## Version Control (Jujutsu)

This repo uses **Jujutsu (jj)** as the version control frontend over Git. Always use `jj` commands instead of raw `git`.

### Key Concepts

- **Changes** (not commits): jj uses immutable changes identified by change IDs
- **Bookmarks** (not branches): `jj bookmark` manages named references
- **Working copy**: The `@` change is always the working copy — edits are automatically tracked
- **No staging area**: All file changes are part of the current change immediately

### Common Commands

```bash
# View history
jj log
jj log -r 'all()'

# View current changes
jj diff
jj status

# Describe current change
jj describe -m "feat: add new module"

# Create a new empty change on top of current
jj new

# Bookmark management
jj bookmark list
jj bookmark set <name> -r <revision>
jj bookmark delete <name>

# Push to remote
jj git push

# Pull from remote
jj git fetch
jj rebase -d main  # rebase onto updated main

# Squash current change into parent
jj squash

# Abandon a change
jj abandon <change-id>

# Move to a different change
jj edit <change-id>
```

### Important Notes

- **Never use `git` directly** unless jj doesn't support the operation
- jj auto-tracks file changes — no `git add` needed
- Use `jj new` after `jj describe` to start a fresh change
- Bookmarks replace branches: `jj bookmark set main -r @`
- The `*` after a bookmark name (e.g., `main*`) means it's ahead of the remote

## Reference Documentation

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)

## Notes

- This configuration uses **unstable** channel by default: `github:nixos/nixpkgs/nixos-unstable`
- Stable channel available as: `nixpkgs-stable` input (nixos-25.11)
- Flakes are enabled with `experimental-features = nix-command flakes`
- System state versions: Check `system.stateVersion` in host configurations
- Custom library functions available via `myLib` special argument
