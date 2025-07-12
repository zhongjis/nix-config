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
nixos-rebuild switch --flake .#framework-16
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
home-manager switch --flake .#zshen@framework-16
home-manager switch --flake .#zshen@Zhongjies-MacBook-Pro
```

### Development Tools

```bash
# Search nixpkgs
nh search <query>

# Update specific flake input
nix run github:zhongjis/nix-update-input

# View secrets (requires sops setup)
nix run nixpkgs#sops -- secrets.yaml
```

### Package Management

```bash
# Build neovim package directly
nix build .#packages.x86_64-linux.neovim
nix build .#packages.aarch64-darwin.neovim
```

## Architecture

### Core Structure

- `flake.nix` - Main flake configuration defining all systems and inputs
- `lib/default.nix` - Custom library functions for system building (`mkSystem`, `mkHome`)
- `modules/` - Modular configuration split by platform:
  - `modules/shared/` - Common configurations for all platforms
  - `modules/nixos/` - NixOS-specific modules
  - `modules/darwin/` - macOS/nix-darwin specific modules
- `hosts/` - Per-machine configurations
- `overlays/` - Package modifications and additions

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

## Host-Specific Notes

**framework-16:**
- AMD Ryzen 7040 series with Radeon 7700s GPU
- Uses Zen kernel for gaming
- Framework-specific fan control via fw-fanctrl

**mac-m1-max:**
- M1 Max MacBook Pro
- Uses nix-darwin for system management
- Homebrew integration for macOS-specific apps