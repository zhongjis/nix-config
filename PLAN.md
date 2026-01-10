# Nix-Config Refactoring Plan: Migration to Flake-Parts

## Overview

Refactor the nix-config repository to use flake-parts for modular flake organization while preserving the bundle/feature enable system and consolidating system-specific logic.

**Goals:**
1. Use flake-parts built-in patterns where possible
2. Replace custom `isDarwin` with `pkgs.stdenv.isDarwin`
3. Keep bundle/feature enable system for programs/features
4. Consolidate nixos/darwin-specific features in the same place
5. Simplify `lib/default.nix` by moving flake helpers to `modules/flake/`

**Non-Goals:**
- Change the existing module structure (features, bundles)
- Modify host configurations
- Change the bundle/feature enable pattern

## Current State Analysis

### Directory Structure

```
nix-config/
├── flake.nix                          # Main flake (175 lines)
├── lib/
│   └── default.nix                    # Custom lib (189 lines)
├── hosts/
│   ├── framework-16/
│   │   ├── configuration.nix          # NixOS config
│   │   ├── home.nix                   # Home Manager config
│   │   └── hardware-configuration.nix
│   └── mac-m1-max/
│       ├── configuration.nix          # Darwin config
│       └── home.nix                   # Home Manager config
├── modules/
│   ├── shared/
│   │   ├── default.nix                # Shared nix module
│   │   ├── cachix.nix
│   │   ├── stylix_common.nix
│   │   ├── nixos/                     # NixOS-specific
│   │   │   ├── default.nix            # Auto-imports features/bundles/services
│   │   │   ├── features/              # Individual features
│   │   │   ├── bundles/               # Feature bundles
│   │   │   └── services/
│   │   ├── home-manager/              # Home Manager
│   │   │   ├── default.nix            # Auto-imports features/bundles
│   │   │   ├── features/
│   │   │   └── bundles/
│   │   └── darwin/                    # Darwin-specific
│   │       └── default.nix            # Auto-imports features/bundles
│   ├── darwin/                        # nix-darwin modules
│   │   ├── default.nix
│   │   ├── home-manager/
│   │   └── features/
│   └── nixos/                         # Additional nix-darwin modules
├── overlays/
│   └── default.nix
└── packages/
    └── helium.nix
```

### Current Issues

1. **`lib/default.nix` does too much:**
   - `mkSystem`: Creates NixOS/Darwin configurations
   - `mkHome`: Creates Home Manager configurations
   - `extendModules`: Auto-creates enable options from files
   - `forAllSystems`: Manual per-system handling
   - `filesIn/dirsIn`: File discovery helpers

2. **Manual `isDarwin` boolean:**
   - Passed through multiple layers
   - Checked in `mkSystem` and `mkHome`
   - Not using built-in `pkgs.stdenv.isDarwin`

3. **Mixed flake outputs:**
   - `nixosConfigurations`, `darwinConfigurations`, `homeConfigurations` defined manually
   - No `perSystem` pattern for packages
   - No devShells or checks defined

4. **Redundant module imports:**
   - `modules/shared/default.nix` imports everything
   - `modules/nixos/default.nix` imports features/bundles
   - `modules/darwin/default.nix` imports features/bundles

## Target State

### Directory Structure

```
nix-config/
├── flake.nix                          # Simplified flake (120 lines)
├── lib/
│   └── default.nix                    # Simplified lib (100 lines)
│                                       # Keep: extendModules, filesIn, dirsIn
│                                       # Remove: mkSystem, mkHome, forAllSystems
├── modules/
│   ├── flake/                         # NEW: Flake-parts modules
│   │   ├── default.nix                # Main flake module
│   │   ├── nixos.nix                  # NixOS helper
│   │   ├── darwin.nix                 # Darwin helper
│   │   └── home.nix                   # Home Manager helper
│   └── ... (rest unchanged)
└── ... (rest unchanged)
```

### Flake Structure

```nix
# flake.nix - TARGET
{
  inputs = { ... };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      imports = [
        ./modules/flake/default.nix
      ];
      
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      
      perSystem = { config, self', pkgs, lib, system, ... }: {
        packages = {
          neovim = ...;
        } // lib.optionalAttrs pkgs.stdenv.isLinux {
          helium = pkgs.callPackage ../packages/helium.nix {};
        };
        
        devShells = {
          default = pkgs.mkShell {
            name = "nix-config-dev";
            packages = with pkgs; [ nix-tree nix-diff nil ];
          };
        };
        
        formatter = pkgs.nixfmt;
        
        checks = {
          # Can add validation checks here
        };
      };
      
      flake = {
        nixosConfigurations = { ... };
        darwinConfigurations = { ... };
        homeConfigurations = { ... };
        templates = { ... };
        
        nixDarwinModules.default = ./modules/darwin;
        homeManagerModules.default = ./modules/shared/home-manager;
        homeManagerModules.linux = ./modules/nixos/home-manager;
        homeManagerModules.darwin = ./modules/darwin/home-manager;
      };
    };
}
```

### Lib Structure

```nix
# lib/default.nix - TARGET
{
  inputs,
  nixpkgs,
  overlays,
  ...
}: let
  # Keep existing helpers that flake-parts doesn't provide
  filesIn = dir: map (fname: dir + "/${fname}")
    (builtins.attrNames (builtins.readDir dir));
  
  dirsIn = dir:
    nixpkgs.lib.filterAttrs (name: value: value == "directory")
    (builtins.readDir dir);
  
  fileNameOf = path:
    (builtins.head (builtins.split "\\." (baseNameOf path)));
  
  # Keep extendModules for bundle/feature system
  extendModule = {path, ...} @ args: {pkgs, ...} @ margs: {
    # ... existing implementation
  };
  
  extendModules = extension: modules:
    map (f: let name = fileNameOf f; in
      (extendModule ((extension name) // {path = f;})))
    modules;
in {
  # Remove mkSystem, mkHome, forAllSystems, pkgsFor
  # Keep only what flake-parts doesn't provide
  inherit filesIn dirsIn fileNameOf extendModule extendModules;
}
```

## Migration Plan

### Phase 1: Infrastructure Setup (1-2 hours)

**Goal:** Create flake-parts module structure

**Steps:**

1.1. Create `modules/flake/` directory
```bash
mkdir -p modules/flake
```

1.2. Create `modules/flake/default.nix`
```nix
# modules/flake/default.nix
{ inputs, config, lib, ... }: {
  imports = [
    ./nixos.nix
    ./darwin.nix
    ./home.nix
  ];
  
  options = {
    myFlake = {
      hosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["framework-16" "mac-m1-max" "thinkpad-t480"];
        description = "List of host names";
      };
      
      homeProfiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "zshen@framework-16"
          "zshen@thinkpad-t480"
          "zshen@Zs-MacBook-Pro"
        ];
        description = "List of home profile names";
      };
    };
  };
}
```

1.3. Create `modules/flake/nixos.nix`
```nix
# modules/flake/nixos.nix
{ inputs, config, lib, ... }: {
  options = myFlake.nixos = {
    createHost = lib.mkOption {
      type = lib.types.functionTo lib.types.anything;
      description = "Create a NixOS host configuration";
    };
  };
  
  config = {
    myFlake.nixos.createHost = hostName: args:
      inputs.nixpkgs.lib.nixosSystem (args // {
        system = args.system or "x86_64-linux";
        specialArgs = {
          inherit inputs;
          # Don't pass myLib anymore - use flake-parts directly
        };
        modules = [
          ../hosts/${hostName}/configuration.nix
          inputs.determinate.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          inputs.stylix.nixosModules.stylix
        ] ++ (args.modules or []);
      });
  };
}
```

1.4. Create `modules/flake/darwin.nix`
```nix
# modules/flake/darwin.nix
{ inputs, config, lib, ... }: {
  options = myFlake.darwin = {
    createHost = lib.mkOption {
      type = lib.types.functionTo lib.types.anything;
      description = "Create a Darwin host configuration";
    };
  };
  
  config = {
    myFlake.darwin.createHost = hostName: args:
      inputs.nix-darwin.lib.darwinSystem (args // {
        system = args.system or "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ../hosts/${hostName}/configuration.nix
          inputs.sops-nix.darwinModules.sops
        ] ++ (args.modules or []);
      });
  };
}
```

1.5. Create `modules/flake/home.nix`
```nix
# modules/flake/home.nix
{ inputs, config, lib, ... }: {
  options = myFlake.home = {
    createProfile = lib.mkOption {
      type = lib.types.functionTo lib.types.anything;
      description = "Create a Home Manager profile";
    };
  };
  
  config = {
    myFlake.home.createProfile = profileName: args:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = args.pkgs or
          (inputs.nixpkgs.legacyPackages.${args.system or "x86_64-linux"});
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ../hosts/${args.host}/home.nix
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
        ] ++ (args.modules or []);
      };
  };
}
```

1.6. Test that flake evaluates
```bash
nix eval .#nixosConfigurations --no-link
nix flake show
```

---

### Phase 2: Simplify lib/default.nix (1 hour)

**Goal:** Remove mkSystem, mkHome, forAllSystems, pkgsFor

**Steps:**

2.1. Review `lib/default.nix` and identify what to keep

**KEEP:**
- `filesIn` - file discovery (flake-parts doesn't provide)
- `dirsIn` - directory discovery (flake-parts doesn't provide)
- `fileNameOf` - utility (flake-parts doesn't provide)
- `extendModule` - for bundle system (flake-parts doesn't provide)
- `extendModules` - for bundle system (flake-parts doesn't provide)

**REMOVE:**
- `mkSystem` - replaced by flake modules
- `mkHome` - replaced by flake modules
- `forAllSystems` - replaced by perSystem
- `pkgsFor` - not needed with perSystem
- `outputs` - available via `inputs.self.outputs`

2.2. Create simplified `lib/default.nix`
```nix
# lib/default.nix - SIMPLIFIED
{
  inputs,
  nixpkgs,
  overlays,
  ...
}: let
  # File discovery helpers (keep - flake-parts doesn't provide)
  filesIn = dir: map (fname: dir + "/${fname}")
    (builtins.attrNames (builtins.readDir dir));
  
  dirsIn = dir:
    nixpkgs.lib.filterAttrs (name: value: value == "directory")
    (builtins.readDir dir);
  
  fileNameOf = path:
    (builtins.head (builtins.split "\\." (baseNameOf path)));
  
  # Bundle/feature system (keep - flake-parts doesn't provide)
  extendModule = {path, ...} @ args: {pkgs, ...} @ margs: let
    eval = if (builtins.isString path) || (builtins.isPath path)
      then import path margs
      else path margs;
    evalNoImports = builtins.removeAttrs eval ["imports" "options"];
    
    extra = if (builtins.hasAttr "extraOptions" args) ||
              (builtins.hasAttr "extraConfig" args)
      then [
        ({...}: {
          options = args.extraOptions or {};
          config = args.extraConfig or {};
        })
      ]
      else [];
  in {
    imports = (eval.imports or []) ++ extra;
    options = if builtins.hasAttr "optionsExtension" args
      then (args.optionsExtension (eval.options or {}))
      else (eval.options or {});
    config = if builtins.hasAttr "configExtension" args
      then (args.configExtension (eval.config or evalNoImports))
      else (eval.config or evalNoImports);
  };
  
  extendModules = extension: modules:
    map (f: let name = fileNameOf f; in
      (extendModule ((extension name) // {path = f;})))
    modules;
in {
  inherit filesIn dirsIn fileNameOf extendModule extendModules;
}
```

2.3. Verify lib still works
```bash
nix eval .#homeConfigurations --no-link
```

---

### Phase 3: Migrate flake.nix to flake-parts (2 hours)

**Goal:** Restructure flake.nix using flake-parts

**Steps:**

3.1. Create new `flake.nix` structure

```nix
# flake.nix - MIGRATED
{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nix-config-private = {
      url = "git+ssh://git@github.com/zhongjis/nix-config-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    aerospace-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake.url = "github:xremap/nix-flake";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    stylix.url = "github:danth/stylix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nvf.url = "github:notashelf/nvf";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };

    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      imports = [
        ./modules/flake/default.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { config, self', pkgs, lib, system, inputs, ... }: let
        overlays = import ./overlays { inherit inputs; };
      in {
        packages = {
          neovim =
            (inputs.nvf.lib.neovimConfiguration {
              inherit pkgs;
              modules = [./modules/shared/home-manager/features/neovim/nvf];
            }).neovim;
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          helium = import ./packages/helium.nix {
            inherit pkgs lib;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            name = "nix-config-dev";
            packages = with pkgs; [
              nix-tree
              nix-diff
              nil
              statix
              deadnix
            ];
          };
        };

        formatter = pkgs.nixfmt;

        checks = {
          # Can add validation checks here
        };
      };

      flake = {
        nixosConfigurations = {
          framework-16 = config.myFlake.nixos.createHost "framework-16" {
            system = "x86_64-linux";
          };
        };

        darwinConfigurations = {
          "Zs-MacBook-Pro" = config.myFlake.darwin.createHost "mac-m1-max" {
            system = "aarch64-darwin";
          };
        };

        homeConfigurations = {
          "zshen@framework-16" = config.myFlake.home.createProfile "zshen@framework-16" {
            host = "framework-16";
            system = "x86_64-linux";
          };
          "zshen@thinkpad-t480" = config.myFlake.home.createProfile "zshen@thinkpad-t480" {
            host = "thinkpad-t480";
            system = "x86_64-linux";
          };
          "zshen@Zs-MacBook-Pro" = config.myFlake.home.createProfile "zshen@Zs-MacBook-Pro" {
            host = "mac-m1-max";
            system = "aarch64-darwin";
          };
        };

        templates = {
          java8 = {
            path = ./templates/java8;
            description = "nix flake new -t github:zhongjis/nix-config#java8 .";
          };
          nodejs22 = {
            path = ./templates/nodejs22;
            description = "nix flake new -t github:zhongjis/nix-config#nodejs22 .";
          };
        };

        nixDarwinModules.default = ./modules/darwin;
        homeManagerModules.default = ./modules/shared/home-manager;
        homeManagerModules.linux = ./modules/nixos/home-manager;
        homeManagerModules.darwin = ./modules/darwin/home-manager;
      };
    };
}
```

3.2. Remove old `with myLib;` pattern
3.3. Test evaluation
```bash
nix eval .# --no-link
nix flake check
```

---

### Phase 4: Replace isDarwin with pkgs.stdenv.isDarwin (1 hour)

**Goal:** Remove manual `isDarwin` boolean from lib and use built-in

**Steps:**

4.1. Update feature modules to use `pkgs.stdenv.isDarwin`

Example - BEFORE:
```nix
# modules/nixos/features/sops.nix
{
  inputs,
  config,
  pkgs,
  lib,
  isDarwin,  # Passed from lib/default.nix
  ...
}: let
  isDarwin = isDarwin;  # Already passed
in {
  sops = {
    age.keyFile = lib.mkDefault "/home/zshen/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;
  };
}
```

Example - AFTER:
```nix
# modules/nixos/features/sops.nix
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  sops = {
    age.keyFile = lib.mkDefault "/home/zshen/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;
  };
}
```

4.2. Files to update:
- `modules/nixos/features/sops.nix`
- `modules/shared/home-manager/features/sops.nix`
- Any other module using `isDarwin`

4.3. Remove `isDarwin` from lib/default.nix args
4.4. Remove `isDarwin` from mkSystem/mkHome specialArgs (already removed in Phase 2)

4.5. Test
```bash
nix eval .#nixosConfigurations.framework-16 --no-link
nix eval .#darwinConfigurations --no-link
```

---

### Phase 5: Consolidate nixos/darwin-specific features (2 hours)

**Goal:** Combine nixos and darwin features in the same module structure

**Approach:** Create a unified module pattern that handles both:

```nix
# modules/shared/features/sops.nix
{ inputs, config, pkgs, lib, ... }: let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  # Base configuration
  environment.systemPackages = with pkgs; [
    sops
    gnupg
  ];
  
  # NixOS-specific
  sops = lib.mkIf isLinux {
    age.keyFile = lib.mkDefault "/home/zshen/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;
  };
  
  # Darwin-specific (via sops-nix)
  sops = lib.mkIf isDarwin {
    # sops-nix handles darwin differently
  };
}
```

**Steps:**

5.1. Identify shared vs. platform-specific features
5.2. Create unified modules where possible
5.3. Keep platform-specific modules where needed
5.4. Test both nixos and darwin hosts

---

### Phase 6: Validation and Cleanup (1-2 hours)

**Goal:** Ensure everything works and clean up

**Steps:**

6.1. Run full validation
```bash
# Evaluate all outputs
nix eval .# --no-link

# Check flake syntax
nix flake check

# Dry-run switch for each host
nh os switch . --dry-run --hostname framework-16
nh os switch . --dry-run --hostname mac-m1-max  # nix-darwin

# Build packages
nix build .#packages.x86_64-linux.neovim
nix build .#packages.aarch64-darwin.neovim
```

6.2. Verify devShell works
```bash
nix develop
echo $EDITOR  # Should be available
```

6.3. Clean up
- Remove old `mkSystem`/`mkHome` references from comments
- Update README with new structure
- Remove backup files if any

---

## Rollback Plan

If something goes wrong:

```bash
# Revert to previous commit
git checkout HEAD~1

# Or use git stash
git stash
git stash pop

# Keep backup of original
cp flake.nix flake.nix.backup
cp lib/default.nix lib/default.nix.backup
```

## Validation Checklist

- [ ] `nix eval .#` succeeds
- [ ] `nix flake check` passes
- [ ] `nix build .#packages.*` builds all packages
- [ ] `nix develop` opens dev shell
- [ ] `nh os switch . --dry-run` works for all hosts
- [ ] All bundles/features still work
- [ ] No regression in functionality

## Time Estimate

| Phase | Time | Total |
|-------|------|-------|
| 1. Infrastructure | 1-2 hours | 1-2h |
| 2. Simplify lib | 1 hour | 2-3h |
| 3. Migrate flake.nix | 2 hours | 4-5h |
| 4. Replace isDarwin | 1 hour | 5-6h |
| 5. Consolidate features | 2 hours | 7-8h |
| 6. Validation | 1-2 hours | 8-10h |

**Total estimated time: 8-10 hours**

## Benefits After Migration

| Aspect | Before | After |
|--------|--------|-------|
| **flake.nix lines** | 175 | ~120 |
| **lib/default.nix lines** | 189 | ~100 |
| **Boilerplate** | Manual forAllSystems | Built-in perSystem |
| **System detection** | Custom `isDarwin` | `pkgs.stdenv.isDarwin` |
| **Dev experience** | Basic | devShells, formatter, checks |
| **Bundle system** | Preserved | Preserved |
| **Multi-system** | Manual | Automatic via perSystem |

## Files Changed

**New files:**
- `modules/flake/default.nix`
- `modules/flake/nixos.nix`
- `modules/flake/darwin.nix`
- `modules/flake/home.nix`

**Modified files:**
- `flake.nix` - Restructured
- `lib/default.nix` - Simplified
- Feature modules - Use `pkgs.stdenv.isDarwin` instead of passed `isDarwin`

**Removed files:**
- None (all changes are modifications)

## Next Steps

1. Get approval for this plan
2. Start Phase 1: Infrastructure Setup
3. Test at each phase before proceeding
4. Update this document with lessons learned
