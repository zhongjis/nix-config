# Flake Update Workflow

Workflow for updating flake inputs and validating changes.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flake Update Workflow                     │
├─────────────────────────────────────────────────────────────┤
│  1. Analyze Current State                                    │
│     → Check all inputs and their current versions            │
│  2. Identify Updates                                         │
│     → Compare against latest versions                        │
│  3. Plan Updates                                             │
│     → Prioritize updates (security, stability, features)     │
│  4. Execute Updates                                          │
│     → Update inputs, test evaluation                         │
│  5. Validate                                                 │
│     → Build test, configuration check                        │
│  6. Commit                                                   │
│     → Document changes, commit to git                        │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Analyze Current State

### Check Current Inputs

```bash
# List all inputs with current refs
nix flake list-inputs

# Show as JSON for processing
nix flake list-inputs --json | jq '.[] | {name: .original.url, current: .ref}'

# Check specific input
nix flake metadata nixpkgs
```

### Evaluate Current State

```bash
# Check if flake evaluates successfully
nix eval .#packages.x86_64-linux.hello --no-link

# List all outputs
nix flake show

# Check system configurations
nix eval .#nixosConfigurations
```

### Check for Updates

```bash
# Check for updates (manual)
nix flake list-inputs --json | jq -r '.[].original.url' | while read url; do
  echo "Checking $url"
  # Manual check of latest version
done

# Or use nix-update-input tool
nix run github:zhongjis/nix-update-input -- help
```

## Step 2: Identify Updates

### Categorize Inputs

| Category | Update Priority | Examples |
|----------|-----------------|----------|
| **Security** | Immediate | nixpkgs, sops-nix |
| **Core** | Regular | home-manager, nix-darwin |
| **Infrastructure** | As needed | disko, flake-parts |
| **Desktop** | Conservative | hyprland, stylix |
| **Development** | Feature-driven | nvf, neovim-nightly |
| **Utilities** | As needed | xremap, colmena |

### Check Update Channels

```bash
# Nixpkgs unstable
nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'

# Check channel
nix-channel --list
nix-channel --update nixos-unstable
```

## Step 3: Plan Updates

### Update Strategy

```markdown
# Planned Updates

## Immediate (Security)
- [ ] nixpkgs: Update to latest unstable
- [ ] sops-nix: Check for security updates

## This Week (Core)
- [ ] home-manager: Latest stable
- [ ] nix-darwin: Latest version

## This Month (Infrastructure)
- [ ] disko: New features
- [ ] flake-parts: Performance improvements

## When Needed (Desktop/Development)
- [ ] hyprland: When new features needed
- [ ] nvf: When neovim update needed
```

### Consider Compatibility

```nix
# Check input compatibility
# Some inputs follow nixpkgs
home-manager.inputs.nixpkgs.follows = "nixpkgs";
# When nixpkgs updates, home-manager auto-updates

# Some inputs have specific versions
nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
```

## Step 4: Execute Updates

### Update All Inputs

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Update to specific ref
nix flake lock --update-input nixpkgs --rev refs/heads/nixos-unstable
```

### Update with Custom Tool

```bash
# Using nix-update-input
nix run github:zhongjis/nix-update-input -- nixpkgs
nix run github:zhongjis/nix-update-input -- home-manager
```

### After Update

```bash
# Regenerate lock file
nix flake lock

# Check changes
git diff flake.lock
```

## Step 5: Validate

### Syntax Validation

```bash
# Check flake syntax
nix-instantiate flake.nix

# Check all configurations
nix-instantiate --eval -E 'builtins.attrNames (import ./flake.nix {})'
```

### Build Test

```bash
# Test package builds
nix build .#packages.x86_64-linux.hello
nix build .#packages.x86_64-linux.neovim

# Test on multiple systems
nix build .#packages.x86_64-linux.hello
nix build .#packages.aarch64-linux.hello --system aarch64-linux
nix build .#packages.aarch64-darwin.hello --system aarch64-darwin
```

### Configuration Test

```bash
# Test NixOS configuration (dry run)
nh os switch . --dry-run

# Test nix-darwin configuration (dry run)
darwin-rebuild build --flake .
```

### Full Validation

```bash
# Complete validation
/validate-config --full
```

## Step 6: Commit

### Document Changes

```bash
# Show what changed
git diff flake.lock | head -50

# Generate update summary
echo "Flake Update Summary" > /tmp/update.md
echo "===================" >> /tmp/update.md
echo "" >> /tmp/update.md
nix flake list-inputs --json | jq -r '.[] | "- \(.original.url): \(.ref)"' >> /tmp/update.md
```

### Commit

```bash
# Stage changes
git add flake.lock

# Commit with message
git commit -m "flake: update inputs

- nixpkgs: Update to latest nixos-unstable
- home-manager: Latest stable release
- (list other changes)

See flake.lock for full details."
```

## Automation Script

```bash
#!/usr/bin/env bash
# scripts/update-flake.sh

set -e

echo "Updating flake inputs..."
nix flake update

echo "Validating..."
nix-instantiate flake.nix > /dev/null

echo "Testing package builds..."
nix build .#packages.x86_64-linux.hello --no-link
nix build .#packages.aarch64-linux.hello --no-link --system aarch64-linux

echo "Changes:"
git diff --stat flake.lock

echo "Done. Review changes before committing."
```

## Troubleshooting

### Update Breaks Evaluation

```bash
# Revert to previous lock file
git checkout flake.lock

# Or rollback specific input
nix flake lock --rollback-input nixpkgs
```

### Incompatible Inputs

```bash
# Check input follows
nix flake metadata home-manager | grep follows

# Update follows manually
# Edit flake.nix to update follows path
```

### Build Failures After Update

```bash
# Check what's failing
nix build .#package 2>&1 | head -50

# May need to update dependent inputs
nix flake update --input nixpkgs
nix flake update --input home-manager
```

## Best Practices

1. **Update nixpkgs regularly** - Security patches
2. **Test before committing** - Dry run and build test
3. **Review flake.lock changes** - Understand what changed
4. **Commit with context** - Document why updates were made
5. **Keep stable branch** - Pin stable versions if needed
6. **Backup before major updates** - Git stash or branch
7. **Use lock file** - Reproducible builds
