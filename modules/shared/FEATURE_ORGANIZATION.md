# Feature Organization Guide

This document describes how features are organized in the nix-config repository and the patterns for platform-specific vs. shared features.

## Directory Structure

```
modules/
├── nixos/                    # NixOS-specific (Linux)
│   ├── features/             # System-level features (boot, services, etc.)
│   ├── bundles/              # Feature bundles
│   └── home-manager/         # HM modules for Linux
│
├── darwin/                   # nix-darwin-specific (macOS)
│   ├── features/             # System-level features (launchd, etc.)
│   ├── bundles/              # Feature bundles
│   └── home-manager/         # HM modules for macOS
│
└── shared/                   # Cross-platform modules
    ├── home-manager/         # HM features (works on both Linux & macOS)
    │   ├── features/         # Dev tools, terminals, editors
    │   └── bundles/          # Home Manager bundles
    ├── stylix_common.nix     # Shared theming
    └── cachix.nix            # Shared cache config
```

## Feature Categories

### Category 1: Platform-Specific System Features

**Linux only (NixOS):**
- `modules/nixos/features/hyprland.nix` - Wayland compositor
- `modules/nixos/features/gdm.nix` - GNOME display manager
- `modules/nixos/features/sddm.nix` - KDE display manager
- `modules/nixos/features/plymouth.nix` - Boot splash

**macOS only (nix-darwin):**
- `modules/darwin/features/sketchybar/` - Status bar
- `modules/darwin/features/skhd/` - Hotkey daemon
- `modules/darwin/features/yabai/` - Window manager

**Pattern:** Keep these separate - they use fundamentally different subsystem APIs.

### Category 2: Cross-Platform System Features

**Use `pkgs.stdenv.isDarwin` for conditional logic:**

```nix
# modules/shared/system/example.nix
{ pkgs, lib, ... }: let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Both platforms share the same module
  services.example = {
    enable = true;
    # Platform-specific config
    package = if isDarwin then pkgs.example-darwin else pkgs.example-linux;
    config = if isDarwin then { darwinOption = true; } else { linuxOption = true; };
  };
}
```

**Examples in codebase:**
- `modules/nixos/features/nh.nix` - Can be unified
- `modules/nixos/features/sops.nix` - Already unified via sops-nix

### Category 3: Home Manager Features (Cross-Platform)

**All features in `modules/shared/home-manager/features/` work on both platforms.**

These configure user-level settings (shell, git, editors, etc.) and use Home Manager's abstraction to work on both Linux and macOS.

**Pattern:** Use `pkgs.stdenv.isDarwin` for conditional logic within HM modules:

```nix
# modules/shared/home-manager/features/example.nix
{ pkgs, lib, ... }: let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  programs.example = {
    enable = true;
    package = if isDarwin then null else pkgs.example-linux;
    settings = {
      # Platform-specific settings
    };
  };
}
```

**Examples:**
- `modules/shared/home-manager/features/ghostty.nix` - Linux only terminal
- `modules/shared/home-manager/features/tmux/default.nix` - Cross-platform
- `modules/shared/home-manager/features/ssh/default.nix` - Cross-platform

## Consolidation Guidelines

### When to Consolidate

1. **Same functionality on both platforms** - Use conditional logic with `pkgs.stdenv.isDarwin`
2. **Minor configuration differences** - Single module with platform-specific options
3. **Shared dependencies** - Package builds available on both platforms

### When to Keep Separate

1. **Fundamentally different APIs** - Hyprland (Linux) vs sketchybar (macOS)
2. **Different subsystem integrations** - systemd services vs launchd
3. **Platform-exclusive features** - Some features only make sense on one platform

## Adding New Features

### For Home Manager Features (User-level)

Add to `modules/shared/home-manager/features/`:
- Works on both platforms automatically
- Use `pkgs.stdenv.isDarwin` for platform-specific logic
- Import pattern: `myHomeManager.{feature}.enable`

### For NixOS/nix-darwin Features (System-level)

1. **Cross-platform:** Add to both `modules/nixos/features/` and `modules/darwin/features/` with similar structure
2. **Platform-specific:** Add to the appropriate platform directory
3. **Consolidatable:** Create a shared module using `pkgs.stdenv.isDarwin` pattern

## Example: Consolidated Feature

Instead of:
```
modules/nixos/features/example.nix
modules/darwin/features/example.nix
```

Consider:
```
modules/shared/nixos/example.nix  # Used by both via imports
```

With content:
```nix
{ pkgs, lib, ... }: let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Unified configuration
  services.example.enable = true;
  
  # Platform-specific options
  services.example.package = if isDarwin
    then pkgs.example-darwin
    else pkgs.example-linux;
}
```

Then import in both platform configurations:
```nix
# In modules/nixos/default.nix and modules/darwin/default.nix
imports = [
  ../../shared/nixos/example.nix
];
```
