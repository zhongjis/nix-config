# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal Nix configuration repository using Nix Flakes to manage multiple systems:
- NixOS systems (framework-16)
- macOS systems via nix-darwin (mac-m1-max)
- Home Manager configurations for user environments

## Common Commands

### System Management

**NixOS:**
```bash
# Switch NixOS configuration
nh os switch .

# Build and switch specific host
nh os switch .#framework-16
```

**macOS (nix-darwin):**
```bash
# Switch darwin configuration
nh darwin switch .

# First time setup
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#mac-m1-max

# List generations and switch
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

**Home Manager:**
```bash
# Switch home-manager configuration
nh home switch .#zshen@framework-16
nh home switch .#zshen@Zhongjies-MacBook-Pro
```

### Development Tools

```bash
# Search nixpkgs
nh search <query>

# Update specific flake input
nix flake update input-name

# View secrets (requires sops setup)
nix run nixpkgs#sops -- secrets.yaml

# Check flake inputs and updates
nix flake show
nix flake check
nix flake update
```

### Package Management

```bash
# Build neovim package directly
nix build .#packages.x86_64-linux.neovim
nix build .#packages.aarch64-darwin.neovim

# Test configurations without switching (safe dry-run commands)
nix flake check                    # Validate flake structure
nix eval .#nixosConfigurations.framework-16.config.system.name
nix eval .#darwinConfigurations.Zs-MacBook-Pro.config.system.name
nix eval .#homeConfigurations."zshen@framework-16".config.home.username
nix build .#packages.x86_64-linux.neovim --no-link
nix build .#nixosConfigurations.framework-16.config.system.build.toplevel --no-link

# Clean up old generations
see helps using `nh clean`

```

## Architecture

### Core Structure

- `flake.nix` - Main flake configuration using flake-parts to organize outputs
  - Uses `flake-parts.lib.mkFlake` to structure outputs
  - `perSystem` defines packages (e.g., neovim) for each system
  - `flake` section contains system configurations (NixOS, Darwin, Home Manager)
- `lib/default.nix` - Custom library functions for module extensions and helpers
  - `extendModule`/`extendModules` - Extends existing modules with additional options/config
  - `filesIn`/`dirsIn` - Directory traversal helpers for modular imports
- `modules/` - Modular configuration split by platform:
  - `modules/shared/` - Common configurations for all platforms
  - `modules/nixos/` - NixOS-specific modules
  - `modules/darwin/` - macOS/nix-darwin specific modules
- `hosts/` - Per-machine configurations (`configuration.nix` and `home.nix`)
- `overlays/` - Package modifications and additions
- `packages/` - Custom packages (e.g., nvf-based Neovim configuration)
- `secrets.yaml` and `secrets/` - SOPS-encrypted secrets

### Module System

The configuration uses a custom module system with automatic enable options:

**NixOS modules** use `myNixOS.<feature>.enable`:
```nix
myNixOS = {
  bundles.general-desktop.enable = true;
  bundles.hyprland.enable = true;
  services.amdgpu.enable = true;
};
```

**Darwin modules** use `myNixDarwin.<feature>.enable`:
```nix
myNixDarwin = {
  bundles.general.enable = true;
  bundles.work.enable = true;
};
```

### Bundle System

Configurations are organized into bundles in `modules/{nixos,darwin}/bundles/`:
- `general-desktop.nix` - Basic desktop environment
- `hyprland.nix` - Hyprland window manager setup
- `gaming.nix` - Gaming-related packages and settings
- `3d-printing.nix` - 3D printing tools

### Key Configuration Areas

**Display/Desktop Environment:**
- Hyprland configuration in `modules/nixos/home-manager/features/hyprland/`
- Waybar, rofi, swaync for desktop environment
- macOS uses Aerospace window manager

**Development Environment:**
- Neovim configuration using nvf framework in `packages/nvf/`
- Terminal setup with alacritty, kitty, ghostty, wezterm options
- Shell configuration with zsh, starship, tmux, zellij

**System Services:**
- GPU support (AMD/NVIDIA) in `modules/nixos/services/`
- Power management for Framework laptop
- Ollama for AI/LLM support

## Secret Management

Uses sops-nix for secret management:
- Age key file: `~/.config/sops/age/keys.txt`
- Secrets stored in `secrets.yaml` and `secrets/homelab.yaml`

## Flake Inputs & Dependencies

Key external inputs used in this configuration:
- `flake-parts` - Framework for organizing flake outputs
- `nixpkgs` (unstable) and `nixpkgs-stable` for packages
- `home-manager` for user environment management
- `nix-darwin` for macOS system configuration  
- `sops-nix` for encrypted secrets management
- `nixos-hardware` for hardware-specific optimizations
- `nix-config-private` - Private configuration repository
- Homebrew taps for macOS apps (aerospace, etc.)

## Flake-Parts Structure

The configuration uses flake-parts to organize outputs:

**Per-System Packages:**
- Defined in `perSystem` section
- Automatically available for all systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`
- Example: `packages.x86_64-linux.neovim`

**System Configurations:**
- NixOS configurations in `nixosConfigurations`
- Darwin configurations in `darwinConfigurations`
- Home Manager configurations in `homeConfigurations`
- All defined explicitly in the `flake` section with:
  - System specification
  - specialArgs (inputs, outputs, myLib)
  - Module lists (host config, hardware modules, SOPS, overlays, etc.)

**Common Helpers:**
- `commonOverlays` - Shared overlays for all systems
- `commonNixpkgsConfig` - Shared nixpkgs configuration
- `mkModuleArgs` - Helper to create module args (_module.args)

## Custom Library Functions

The `lib/default.nix` provides helper functions:
- `extendModule`/`extendModules` - Extends existing modules with additional options/config
- `filesIn`/`dirsIn` - Directory traversal helpers for modular imports
- `pkgsFor` - Get nixpkgs for a specific system

## Host-Specific Notes

**framework-16:**
- AMD Ryzen 7040 series with Radeon 7700s GPU
- Uses Zen kernel for gaming
- Framework-specific fan control via fw-fanctrl

**mac-m1-max:**
- M1 Max MacBook Pro
- Uses nix-darwin for system management
- Homebrew integration for macOS-specific apps
