# Current Flake Structure

Analysis of the current flake.nix structure and patterns used in the nix-config repository.

## Current Structure Overview

```
flake.nix
├── inputs (20+ inputs)
├── let bindings (overlays, myLib)
└── outputs (nixos, darwin, home, packages, templates, modules)
```

### Input Categories

#### Core Infrastructure
```nix
# Core system frameworks
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
nixos-hardware.url = "github:nixos/nixos-hardware/master";
home-manager.url = "github:nix-community/home-manager";
nix-darwin.url = "github:LnL7/nix-darwin";
```

#### Secret Management
```nix
sops-nix.url = "github:Mic92/sops-nix";
```

#### Desktop Environments
```nix
# Hyprland ecosystem
hyprland.url = "github:hyprwm/Hyprland";
hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
hy3.url = "github:outfoxxed/hy3";
hypr-dynamic-cursors.url = "github:VirtCode/hypr-dynamic-cursors";

# Theming
stylix.url = "github:danth/stylix";
```

#### Development Tools
```nix
# Neovim
neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
nvf.url = "github:notashelf/nvf";

# Terminal & Tools
colmena.url = "github:zhaofengli/colmena";
xremap-flake.url = "github:xremap/nix-flake";
minimal-tmux.url = "github:niksingh710/minimal-tmux-status";
```

#### Gaming & Media
```nix
nix-gaming.url = "github:fufexan/nix-gaming";
```

#### System Tools
```nix
# Package management
nix-flatpak.url = "github:gmodena/nix-flatpak";
nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

# Infrastructure
disko.url = "github:nix-community/disko";
determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
flake-parts.url = "github:hercules-ci/flake-parts";

# Hardware
fw-fanctrl.url = "github:TamtamHero/fw-fanctrl/packaging/nix";
```

#### Private
```nix
nix-config-private.url = "git+ssh://git@github.com/zhongjis/nix-config-private.git";
```

## Current Output Structure

### NixOS Configurations

```nix
nixosConfigurations = {
  framework-16 = mkSystem "framework-16" {
    system = "x86_64-linux";
    hardware = "framework-16-7040-amd";
    user = "zshen";
  };
};
```

### Darwin Configurations

```nix
darwinConfigurations = {
  Zs-MacBook-Pro = mkSystem "mac-m1-max" {
    system = "aarch64-darwin";
    user = "zshen";
    darwin = true;
  };
};
```

### Home Manager Configurations

```nix
homeConfigurations = {
  "zshen@Zs-MacBook-Pro" = mkHome "mac-m1-max" {
    system = "aarch64-darwin";
    darwin = true;
  };
  "zshen@thinkpad-t480" = mkHome "thinkpad-t480" {
    system = "x86_64-linux";
  };
  "zshen@framework-16" = mkHome "framework-16" {
    system = "x86_64-linux";
  };
};
```

### Packages

```nix
packages = forAllSystems (pkgs: let
  inherit (pkgs.lib) optionalAttrs;
in {
  neovim = (nvf.lib.neovimConfiguration {
    pkgs = pkgs;
    modules = [./modules/shared/home-manager/features/neovim/nvf];
  }).neovim;
} // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  helium = import ./packages/helium.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
});
```

### Templates

```nix
templates = {
  java8 = {
    path = ./templates/java8;
    description = "...";
  };
  nodejs22 = {
    path = ./templates/nodejs22;
    description = "...";
  };
};
```

### Modules

```nix
nixDarwinModules.default = ./modules/darwin;
homeManagerModules.default = ./modules/shared/home-manager;
homeManagerModules.linux = ./modules/nixos/home-manager;
homeManagerModules.darwin = ./modules/darwin/home-manager;
```

## Lib Helper Functions

### mkSystem

```nix
mkSystem = hostName: {
  system,
  user,
  hardware ? "",
  darwin ? false,
}: let
  isDarwin = darwin;
  hostConfiguration = ../hosts/${hostName}/configuration.nix;
  systemFunc = if isDarwin
    then inputs.nix-darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  hardwareConfiguration = if hardware != ""
    then inputs.nixos-hardware.nixosModules.${hardware}
    else {};
  determinateModule = if isDarwin then {} else inputs.determinate.nixosModules.default;
  sopsModule = if isDarwin
    then inputs.sops-nix.darwinModules.sops
    else inputs.sops-nix.nixosModules.sops;
in
  systemFunc {
    inherit system;
    specialArgs = { inherit inputs outputs myLib; };
    modules = [
      hostConfiguration
      hardwareConfiguration
      determinateModule
      sopsModule
      {
        nixpkgs.overlays = [ ... ];
        nixpkgs.config = { allowUnfree = true; };
      }
      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = hostName;
          currentSystemUser = user;
          inherit inputs;
          isDarwin = darwin;
        };
      }
    ];
  };
```

### mkHome

```nix
mkHome = systemName: {
  system,
  darwin ? false,
}: let
  currentSystem = system;
  currentSystemName = systemName;
  isDarwin = darwin;
  homeConfiguration = ../hosts/${systemName}/home.nix;
in
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ ... ];
    };
    extraSpecialArgs = {
      inherit inputs outputs myLib currentSystem currentSystemName isDarwin;
    };
    modules = [
      homeConfiguration
      inputs.sops-nix.homeManagerModules.sops
      inputs.stylix.homeModules.stylix
    ];
  };
```

## Overlay Structure

```nix
# overlays/default.nix
{ inputs, ... }: {
  modifications = final: prev: {
    # Overlay modifications
    vimPlugins = prev.vimPlugins // {
      trouble-nvim = prev.vimUtils.buildVimPlugin {
        name = "trouble.nvim";
        src = inputs.trouble-nvim;
      };
    };
  };
  
  stable-packages = final: prev: {
    # Stable package versions
  };
}
```

## Patterns Used

### Conditional Attributes

```nix
# Conditional on system
packages = forAllSystems (pkgs: {
  neovim = ...;
} // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  helium = import ./packages/helium.nix { inherit pkgs; };
});
```

### Input Following

```nix
# Following nixpkgs
home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Lazy Evaluation

```nix
# Lib helpers for lazy loading
filesIn = dir: (map (fname: dir + "/${fname}")
  (builtins.attrNames (builtins.readDir dir)));
```

## Issues Identified

1. **No flake-parts integration** - Current outputs are manually structured
2. **No perSystem pattern** - System-specific packages require manual handling
3. **No devShells** - No development shell definitions
4. **No checks** - No validation checks defined
5. **Large mkSystem/mkHome** - Could be simplified with flake-parts
6. **Conditional packages** - `optionalAttrs` pattern is verbose

## Target Structure (with flake-parts)

See `context/domain/target-structure.md` for the migrated structure.
