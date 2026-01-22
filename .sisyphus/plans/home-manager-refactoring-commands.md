# Home-Manager Module Refactoring - Implementation Commands

This document provides the exact commands to execute the refactoring plan.

## Pre-Flight Checks

```bash
# 1. Ensure you're on the right branch
git status

# 2. Create a backup branch
git checkout -b backup/pre-home-manager-refactor

# 3. Return to main/master
git checkout main  # or master, or your working branch

# 4. Create refactoring branch
git checkout -b refactor/home-manager-structure

# 5. Verify current system builds
nix flake check
```

## Phase 1: Create Directory Structure

```bash
# Create all needed subdirectories
mkdir -p modules/home-manager/{bundles,features,services}
mkdir -p modules/home-manager-linux/{bundles,features,services}
mkdir -p modules/home-manager-darwin/{bundles,features,services}

# Verify creation
ls -la modules/home-manager/
ls -la modules/home-manager-linux/
ls -la modules/home-manager-darwin/
```

## Phase 2: Move Files (Batch 1 - Bundles)

### Shared Bundles

```bash
cd modules/home-manager

# Move and rename bundles (use git mv to preserve history)
git mv bundle-general.nix bundles/general.nix
git mv bundle-general-server.nix bundles/general-server.nix
git mv bundle-office.nix bundles/office.nix

cd ../..
```

### Linux Bundles

```bash
cd modules/home-manager-linux

git mv bundle-hyprland.nix bundles/hyprland.nix
git mv bundle-linux.nix bundles/linux.nix

cd ../..
```

### Darwin Bundles

```bash
cd modules/home-manager-darwin

git mv bundle-darwin.nix bundles/darwin.nix

cd ../..
```

### Verify Batch 1

```bash
# Check that bundles are in place
ls -la modules/home-manager/bundles/
ls -la modules/home-manager-linux/bundles/
ls -la modules/home-manager-darwin/bundles/

# Test (will fail, but should show moved files)
nix flake check 2>&1 | head -20
```

## Phase 2: Move Files (Batch 2 - Services)

### Shared Services

```bash
cd modules/home-manager

git mv tmux services/
git mv wlogout services/

cd ../..
```

### Linux Services

```bash
cd modules/home-manager-linux

git mv dunst.nix services/
git mv hypridle.nix services/
git mv swaync services/
git mv waybar services/

cd ../..
```

### Verify Batch 2

```bash
ls -la modules/home-manager/services/
ls -la modules/home-manager-linux/services/
```

## Phase 2: Move Files (Batch 3 - Features)

### Shared Features (Simple Files)

```bash
cd modules/home-manager

git mv alacritty.nix features/
git mv cht-sh.nix features/
git mv direnv.nix features/
git mv fastfetch.nix features/
git mv fzf.nix features/
git mv ghostty.nix features/
git mv git.nix features/
git mv gtk.nix features/
git mv kitty.nix features/
git mv kubernetes.nix features/
git mv lazygit.nix features/
git mv mcp.nix features/
git mv rg.nix features/
git mv sops.nix features/
git mv starship.nix features/
git mv stylix.nix features/
git mv wezterm.nix features/
git mv yazi.nix features/
git mv zed.nix features/
git mv zen-browser.nix features/

cd ../..
```

### Shared Features (Subdirectories)

```bash
cd modules/home-manager

git mv claude-code features/
git mv neovim features/
git mv opencode features/
git mv ssh features/
git mv zellij features/
git mv zsh features/

cd ../..
```

### Linux Features (Simple Files)

```bash
cd modules/home-manager-linux

git mv distrobox.nix features/
git mv hyprpaper.nix features/
git mv hyprsunset.nix features/
git mv pipewire-noise-cancling-input.nix features/

cd ../..
```

### Linux Features (Subdirectories)

```bash
cd modules/home-manager-linux

git mv hyprland features/
git mv hyprlock features/
git mv rofi features/

cd ../..
```

### Darwin Features

```bash
cd modules/home-manager-darwin

git mv aerospace features/

cd ../..
```

### Verify Batch 3

```bash
# Check feature counts
ls -1 modules/home-manager/features/ | wc -l       # Should be 26 (20 files + 6 subdirs)
ls -1 modules/home-manager-linux/features/ | wc -l  # Should be 7 (4 files + 3 subdirs)
ls -1 modules/home-manager-darwin/features/ | wc -l # Should be 1 (1 subdir)

# Verify only default.nix remains in root
ls -la modules/home-manager/
ls -la modules/home-manager-linux/
ls -la modules/home-manager-darwin/
```

## Phase 3: Update default.nix Files

These files need manual editing. Use your editor to update them according to the plan.

### Files to Edit:

1. `modules/home-manager/default.nix`
2. `modules/home-manager-linux/default.nix`
3. `modules/home-manager-darwin/default.nix`

### Template for all three (adjust namespace):

```nix
{
  lib,
  config,
  myLib,
  ...
}: let
  cfg = config.myHomeManager;  # Or myHomeManagerLinux / myHomeManagerDarwin

  # Scan features/ subdirectory
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (myLib.filesIn ./features);

  # Scan bundles/ subdirectory (no prefix stripping needed)
  bundles =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.bundles.${name}.enable = lib.mkEnableOption "enable ${name} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${name}.enable config);
    })
    (myLib.filesIn ./bundles);

  # NEW: Scan services/ subdirectory
  services =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.services.${name}.enable = lib.mkEnableOption "enable ${name} service";
      };

      configExtension = config: (lib.mkIf cfg.services.${name}.enable config);
    })
    (myLib.filesIn ./services);
in {
  imports =
    []
    ++ features
    ++ bundles
    ++ services;  # NEW: Add services

  # Keep existing config below...
  xdg.enable = true;
  # ... etc
}
```

### Quick Edit Commands (if you want to use sed):

**Note**: Better to manually edit to ensure correctness. These are reference only.

```bash
# Backup first
cp modules/home-manager/default.nix modules/home-manager/default.nix.backup
cp modules/home-manager-linux/default.nix modules/home-manager-linux/default.nix.backup
cp modules/home-manager-darwin/default.nix modules/home-manager-darwin/default.nix.backup
```

## Phase 4: Update Bundle References

### Update `modules/home-manager/bundles/general.nix`

```bash
# Edit the file to change tmux reference
# Change: myHomeManager.tmux.enable
# To: myHomeManager.services.tmux.enable
```

Manual edit required. Look for line:
```nix
myHomeManager.tmux.enable = lib.mkDefault true;
```

Change to:
```nix
myHomeManager.services.tmux.enable = lib.mkDefault true;
```

### Update `modules/home-manager-linux/bundles/hyprland.nix`

Manual edit required. Look for these lines:
```nix
myHomeManager.hypridle.enable = true;
myHomeManager.dunst.enable = true;
myHomeManager.waybar.enable = true;
# myHomeManager.wlogout.enable = true;
# myHomeManager.swaync.enable = true;
```

Change to:
```nix
myHomeManager.services.hypridle.enable = true;
myHomeManager.services.dunst.enable = true;
myHomeManager.services.waybar.enable = true;
# myHomeManager.services.wlogout.enable = true;
# myHomeManager.services.swaync.enable = true;
```

## Phase 5: Testing

### Test Flake Evaluation

```bash
# Should pass now if all edits are correct
nix flake check
```

### Test Home-Manager Builds (without switching)

```bash
# Linux home configuration
nix build .#homeConfigurations."zshen@framework-16".activationPackage

# Darwin home configuration
nix build .#homeConfigurations."zshen@Zhongjies-MacBook-Pro.local".activationPackage
```

### Test Full System Builds

```bash
# NixOS (if on Linux)
nix build .#nixosConfigurations.framework-16.config.system.build.toplevel

# Darwin (if on macOS)
nix build .#darwinConfigurations.mac-m1-max.system
```

### Switch Systems (Final Test)

```bash
# On Linux:
nh os switch .

# On Darwin:
nh darwin switch .
```

## Rollback Plan (If Something Goes Wrong)

```bash
# Quick rollback to backup branch
git checkout backup/pre-home-manager-refactor

# Or reset if on refactor branch
git reset --hard HEAD~1  # Repeat as needed

# Or use nix-darwin/nixos generations
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation <number>

# Or on NixOS
nixos-rebuild --list-generations
sudo nixos-rebuild switch --rollback
```

## Commit Strategy

```bash
# Stage all moves and changes
git add -A

# Check what's staged
git status

# Commit with descriptive message
git commit -m "refactor(home-manager): organize modules into bundles/features/services

- Create bundles/, features/, services/ subdirectories in all home-manager module locations
- Move and rename bundles (strip bundle- prefix)
- Categorize modules as features vs services
- Update default.nix files to scan subdirectories
- Update bundle references to use .services namespace where applicable

This brings home-manager module organization in line with NixOS and Darwin patterns."

# Push to remote (if applicable)
git push origin refactor/home-manager-structure
```

## Verification Checklist

After completing all phases:

- [ ] All files moved to correct subdirectories
- [ ] No orphaned files in root module directories (except default.nix)
- [ ] All three default.nix files updated
- [ ] Bundle references updated (2 files)
- [ ] `nix flake check` passes
- [ ] Home-manager configurations build
- [ ] Full system configurations build
- [ ] System switches successfully
- [ ] All enabled features/services still work
- [ ] Changes committed with descriptive message

## Post-Refactoring Tasks

1. Update `AGENTS.md` documentation
2. Test on both systems (Linux and Darwin)
3. Monitor for any runtime issues over next few days
4. Consider updating README if it references module structure

## Time Estimate

- Phase 1: 5 minutes
- Phase 2: 15 minutes (all batches)
- Phase 3: 20 minutes (manual editing)
- Phase 4: 5 minutes (manual editing)
- Phase 5: 20 minutes (testing)
- Commit: 5 minutes

**Total: ~70 minutes (1 hour 10 minutes)**

