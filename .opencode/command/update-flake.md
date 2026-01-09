---
command: /update-flake
description: Update all flake inputs or specific inputs
syntax: |
  /update-flake [options]
options:
  - --input <name>: Update specific input
  - --validate: Validate after update
  - --commit: Commit changes automatically
  - --dry-run: Show what would be updated
examples:
  - "/update-flake"
  - "/update-flake --input nixpkgs --validate"
  - "/update-flake --dry-run"
---

# Update Flake Command

Updates flake inputs to their latest versions.

## Usage

```bash
/update-flake                    # Update all inputs
/update-flake --dry-run          # Preview changes
/update-flake --input nixpkgs    # Update specific input
/update-flake --validate         # Validate after update
/update-flake --commit           # Auto-commit
```

## Examples

### Update All Inputs

```bash
$ /update-flake

=== Updating Flake Inputs ===
Updating all inputs...
✅ Updated: nixpkgs (nixos-unstable)
✅ Updated: home-manager
✅ Updated: nix-darwin
✅ Updated: sops-nix
✅ Updated: hyprland
...

=== Changes ===
flake.lock updated
Run /validate-config to verify
```

### Dry Run

```bash
$ /update-flake --dry-run

=== Update Preview ===
Would update:
- nixpkgs: nixos-unstable → nixos-unstable (latest)
- home-manager: latest → latest
- ...

Would NOT update:
- nixpkgs-stable: pinned to 25.11
- (inputs with explicit revs)

Run without --dry-run to execute
```

### Specific Input

```bash
$ /update-flake --input nixpkgs --validate

=== Updating nixpkgs ===
🔄 Fetching latest nixpkgs...
✅ Updated to: nixos-unstable

=== Validating ===
✅ Syntax OK
✅ Evaluation OK
✅ Packages build OK

=== Summary ===
Updated: nixpkgs → nixos-unstable
Run /validate-config for full validation
```

## What Gets Updated

| Input | Update Behavior |
|-------|-----------------|
| `nixpkgs` (unstable) | Updates on each run |
| `home-manager` | Updates (follows nixpkgs) |
| `nix-darwin` | Updates (follows nixpkgs) |
| `sops-nix` | Updates |
| `nixpkgs-stable` | Stays on 25.11 (pinned) |
| `inputs with rev=` | Not updated (pinned) |

## Validation

After update, automatically validates:

```bash
# Syntax check
nix-instantiate flake.nix

# Package builds
nix build .#packages.x86_64-linux.hello

# Configuration evaluation
nix eval .#nixosConfigurations
```

## Best Practices

1. **Update regularly** - Security patches in nixpkgs
2. **Validate before use** - Always test after update
3. **Review changes** - Check flake.lock diff
4. **Commit with context** - Document what changed
5. **Test on target system** - Real hardware validation
