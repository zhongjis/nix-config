# Flake Update Workflow

Workflow for updating flake inputs and validating changes.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flake Update Workflow                     │
├─────────────────────────────────────────────────────────────┤
│  1. Analyze Current State                                    │
│  2. Identify Updates                                         │
│  3. Plan Updates                                             │
│  4. Execute Updates                                          │
│  5. Validate                                                 │
│  6. Commit                                                   │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Analyze Current State

```bash
# List all inputs
nix flake list-inputs

# Check current versions
nix flake metadata nixpkgs

# Evaluate current state
nix eval .#packages.x86_64-linux.hello --no-link
```

## Step 2: Identify Updates

```bash
# Check for updates (manual)
nix flake list-inputs --json | jq '.[].ref'

# Or use custom tool
nix run github:zhongjis/nix-update-input -- --help
```

## Step 3: Plan Updates

Categorize by priority:

| Priority | Inputs | Update Frequency |
|----------|--------|------------------|
| **Security** | nixpkgs, sops-nix | Immediate |
| **Core** | home-manager, nix-darwin | Regular |
| **Infrastructure** | disko, flake-parts | As needed |
| **Desktop** | hyprland, stylix | Conservative |
| **Utilities** | xremap, colmena | As needed |

## Step 4: Execute Updates

```bash
# Update all
nix flake update

# Update specific
nix flake lock --update-input nixpkgs

# Regenerate lock
nix flake lock
```

## Step 5: Validate

```bash
# Check syntax
nix-instantiate flake.nix

# Test packages
nix build .#packages.*

# Dry-run switch
nh os switch . --dry-run

# Full validation
/validate-config --full
```

## Step 6: Commit

```bash
# Stage changes
git add flake.lock

# Commit
git commit -m "flake: update inputs

- nixpkgs: Update to latest nixos-unstable
- home-manager: Latest stable release

See flake.lock for full details."
```

## Troubleshooting

### Update Breaks Evaluation

```bash
# Revert
git checkout flake.lock
```

### Build Fails After Update

```bash
# Check what's failing
nix build .#package 2>&1 | tail -50

# May need to update other inputs
nix flake update --input nixpkgs
nix flake update --input home-manager
```

## Schedule

- **Daily**: Check for critical updates
- **Weekly**: Regular update cycle
- **Monthly**: Full review of all inputs
