---
command: /switch-host
description: Switch to a specific host configuration
syntax: |
  /switch-host <host> [options]
options:
  - --dry-run: Test without applying
  - --validate: Run full validation
  - --generation <n>: Switch to specific generation
examples:
  - "/switch-host framework-16"
  - "/switch-host framework-16 --dry-run"
  - "/switch-host mac-m1-max --validate"
  - "/switch-host framework-16 --generation 41"
---

# Switch Host Command

Switches to a specific host configuration with validation.

## Usage

```bash
/switch-host <host>              # Standard switch
/switch-host <host> --dry-run    # Test first
/switch-host <host> --validate   # Full validation
/switch-host <host> --generation 41  # Specific generation
```

## Available Hosts

| Host | OS | Profile |
|------|-----|---------|
| `framework-16` | NixOS | Desktop + Gaming |
| `mac-m1-max` | macOS | Full macOS |
| `thinkpad-t480` | NixOS | (configured, inactive) |

## Examples

### Switch to Framework-16

```bash
$ /switch-host framework-16

=== Switching to framework-16 ===

1. Validating configuration...
✅ Syntax OK
✅ Imports OK
✅ Evaluation OK

2. Building...
✅ Build successful

3. Preparing switch...
The following profiles will be activated:
- /nix/var/nix/profiles/system (NixOS)
- /nix/var/nix/profiles/per-user/zshen/home-manager (HM)

Proceed with switch? (y/n)
```

### Dry Run

```bash
$ /switch-host framework-16 --dry-run

=== Dry Run: framework-16 ===

1. Configuration Check
✅ Syntax valid
✅ All imports resolve
✅ Options valid

2. Build Test
✅ System derivation builds
✅ Packages build OK

3. Changes Summary
The following will change:
- kernel: 6.12.0 → 6.12.1
- home-manager: will be reconfigured
- packages: +2 new, -0 removed

No switch performed (dry run)
```

### Switch to Specific Generation

```bash
$ /switch-host framework-16 --generation 41

=== Generation 41 ===

Generation 41 was created: 2025-01-05 12:00:00
Contains:
- nixpkgs: nixos-unstable
- home-manager: latest
- Changes: "flake: update inputs"

Switch to this generation? (y/n)
```

### Full Validation

```bash
$ /switch-host framework-16 --validate

=== Full Validation ===

1. Syntax ✅
2. Imports ✅
3. Evaluation ✅
4. Package Build ✅
   - neovim: OK
   - helium: OK
   - hello: OK
5. Secrets ✅
6. Modules ✅
7. Network Config ✅
8. Hardware Config ✅

All validations passed. Ready to switch.
```

## Pre-Switch Checklist

Before switching, the system checks:

- [x] Syntax validity
- [x] Import resolution
- [x] Option validity
- [x] Package builds
- [x] Secret files valid
- [x] Module structure
- [x] Network configuration
- [x] Hardware compatibility

## Rollback

If something goes wrong:

```bash
# Rollback to previous generation
sudo nix-env -p /nix/var/nix/profiles/system --rollback

# Or use GRUB to select previous generation
```

## Post-Switch Verification

After switching:

```bash
# Verify system
nixos-version
fastfetch

# Check services
systemctl list-units --type=service --state=running | head -10

# Check Home Manager
home-manager packages | head -5
```
