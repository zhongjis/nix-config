# Host Switch Workflow

Workflow for switching between system configurations using nh tool.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Host Switch Workflow                       │
├─────────────────────────────────────────────────────────────┤
│  1. Validate Configuration                                   │
│     → Check syntax and imports                               │
│  2. Dry-Run Build                                            │
│     → Test build without switching                           │
│  3. Review Changes                                           │
│     → Check what will change                                 │
│  4. Execute Switch                                           │
│     → Apply configuration                                    │
│  5. Verify                                                   │
│     → Confirm system works correctly                         │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Validate Configuration

### Syntax Check

```bash
# Check flake syntax
nix-instantiate flake.nix

# Check host configuration syntax
nix-instantiate --eval -E '
  let
    host = (import ./hosts/framework-16/configuration.nix {
      pkgs = import <nixpkgs> {};
      lib = (import <nixpkgs> {}).lib;
      config = {};
    });
  in
    if host ? config then "OK" else "FAIL"
'

# Validate all imports
/check-modules --detailed
```

### Import Validation

```bash
# Check all imports exist
nix eval .#nixosConfigurations.framework-16 --no-link 2>&1 | head -20

# Check for missing imports
nix-instantiate --parse ./hosts/framework-16/configuration.nix | head -10
```

## Step 2: Dry-Run Build

### NixOS Dry Run

```bash
# Dry run (no changes)
nh os switch . --dry-run

# Dry run with output
nh os switch . --dry-run --show-trace

# Build only (no switch)
nix build .#nixosConfigurations.framework-16.config.system.build.toplevel
```

### Darwin Dry Run

```bash
# Dry run
darwin-rebuild build --flake . --dry-run

# With show-trace
darwin-rebuild build --flake . --show-trace
```

### Check Generations

```bash
# List current generations
nh os switch . --list-generations

# Or
nix-instantiate --eval -E '
  let
    gen = (import ./flake.nix {}).nixosConfigurations.framework-16.config.system.build;
  in
    gen
'
```

## Step 3: Review Changes

### What Will Change

```bash
# Check diff of generated files
nh os switch . --dry-run 2>&1 | grep -A5 "changed"

# Check profile changes
nix profile history /nix/var/nix/profiles/system

# Compare generations
nh os switch . --compare-generations 41
```

### Package Changes

```bash
# Check package additions/removals
nix-env -q --profiles /nix/var/nix/profiles/system

# Check new packages
nix-instantiate --eval -E '
  let
    pkgs = (import ./flake.nix {}).packages.x86_64-linux;
  in
    builtins.attrNames pkgs
'
```

## Step 4: Execute Switch

### NixOS Switch

```bash
# Standard switch
nh os switch .

# With confirmation
echo "y" | nh os switch .

# Switch to specific generation
nh os switch . --switch-generation 41

# Switch with rollback on failure
nh os switch . --rollback
```

### Darwin Switch

```bash
# Standard switch
nh darwin switch .

# Build only
darwin-rebuild switch --flake .

# Switch specific generation
darwin-rebuild switch --switch-generation 41 --flake .
```

### Home Manager Switch

```bash
# Framework-16
home-manager switch --flake .#zshen@framework-16

# MacBook Pro
home-manager switch --flake .#zshen@Zs-MacBook-Pro

# With confirmation
home-manager switch --flake .#zshen@framework-16 --impure
```

## Step 5: Verify

### Check System Status

```bash
# Check system info
fastfetch

# Check running services
systemctl list-units --type=service --state=running | head -20

# Check NixOS generation
nixos-version

# Check Home Manager
home-manager packages | head -10
```

### Test Key Features

```bash
# Test terminal
alacritty --version

# Test editor
nvim --version

# Test shell
echo $SHELL

# Test config files
cat ~/.config/nvim/init.lua | head -10
```

### Verify Secrets

```bash
# Check secrets deployed
ls /run/secrets/

# Test secret access
cat /run/secrets/api-token
```

## Rollback Procedures

### If Something Breaks

```bash
# Rollback to previous generation
sudo nix-env -p /nix/var/nix/profiles/system --rollback

# Or via generation
sudo /nix/var/nix/profiles/system-41-link/bin/switch-to-configuration boot

# Check generations
grub = {
  enable = true;
  device = "nodev";
  efiSupport = true;
  useOSProber = true;
};
```

### Emergency Recovery

```bash
# Boot previous generation via GRUB menu
# Select "NixOS - Previous configuration"

# Fix issue, then switch again
```

## Switching Between Hosts

### Framework-16 (NixOS)

```bash
# Switch to framework-16
nh os switch . --flake .#framework-16

# Or if in project root
nh os switch .
```

### MacBook Pro (Darwin)

```bash
# Switch to macOS
nh darwin switch . --flake .#Zs-MacBook-Pro

# Or
darwin-rebuild switch --flake .#Zs-MacBook-Pro
```

### Multiple Profiles

```bash
# Framework-16 HM profile
home-manager switch --flake .#zshen@framework-16

# MacBook HM profile
home-manager switch --flake .#zshen@Zs-MacBook-Pro

# thinkpad-t480 HM profile
home-manager switch --flake .#zshen@thinkpad-t480
```

## Automation

### Switch Script

```bash
#!/usr/bin/env bash
# scripts/switch-host.sh

HOST="${1:-framework-16}"

echo "Switching to $HOST..."

# Validate
nh os switch . --dry-run --flake ".#$HOST"

if [ $? -eq 0 ]; then
  echo "Changes validated. Proceed with switch? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    nh os switch . --flake ".#$HOST"
    echo "Switch complete!"
  else
    echo "Switch cancelled."
  fi
else
  echo "Validation failed. Check errors above."
  exit 1
fi
```

## Troubleshooting

### Switch Fails

```bash
# Check error details
nh os switch . --show-trace

# Common issues:
# - Syntax error in configuration
# - Missing import
# - Circular dependency
# - Package not found
```

### Build Fails

```bash
# Check build error
nix build .#nixosConfigurations.framework-16.config.system.build.toplevel 2>&1 | tail -50

# Clean build cache
nix-collect-garbage -d

# Retry
nh os switch .
```

### Service Fails to Start

```bash
# Check service status
systemctl status my-service

# Check logs
journalctl -u my-service -e

# Restart service
sudo systemctl restart my-service
```

## Best Practices

1. **Always dry-run first** - Catch issues before switching
2. **Check what changes** - Understand impact before applying
3. **Keep working generation** - Don't delete previous generation
4. **Test in VM first** - For major changes
5. **Document changes** - Commit with clear message
6. **Verify after switch** - Confirm everything works
7. **Know rollback procedure** - Be prepared for issues
8. **Back up critical data** - Before major changes
