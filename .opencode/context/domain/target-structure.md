# Target Flake-Parts Structure

Target structure for migrating the nix-config repository to use flake-parts.

## Migration Goals

1. **Modularity**: Use NixOS module system for flake structure
2. **Cleaner Code**: Reduce boilerplate with perSystem
3. **Multi-System**: Built-in support for all architectures
4. **Lazy Evaluation**: Use partitions for faster iteration
5. **Reusability**: Export modules for other flakes

## Target Structure Overview

```
flake.nix
├── inputs (with flake-parts)
├── outputs = flake-parts.mkFlake {
│   ├── imports (reusable modules)
│   ├── systems (supported architectures)
│   ├── perSystem (system-specific outputs)
│   └── flake (system-independent outputs)
│
├── modules/
│   └── flake/
│       ├── default.nix          # Main flake module
│       ├── nixos.nix            # NixOS helper
│       ├── darwin.nix           # Darwin helper
│       └── home.nix             # Home Manager helper
```

## New Flake Structure

```nix
{
  description = "Nixos config flake";
  
  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    
    # Flake system
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    # Infrastructure
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    
    # Desktop
    stylix.url = "github:danth/stylix";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    
    # Development
    nvf.url = "github:notashelf/nvf";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hardware
    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # ... other inputs
  };
  
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
      
      perSystem = { config, self', pkgs, lib, system, inputs, ... }: {
        # Packages
        packages = {
          neovim = (inputs.nvf.lib.neovimConfiguration {
            pkgs = pkgs;
            modules = [../modules/shared/home-manager/features/neovim/nvf];
          }).neovim;
        } // lib.optionalAttrs pkgs.stdenv.isLinux {
          helium = pkgs.callPackage ../packages/helium.nix {};
        };
        
        # Dev shells
        devShells = {
          default = pkgs.mkShell {
            name = "nix-config-dev";
            packages = with pkgs; [
              nix-tree
              nix-diff
              nil
            ];
          };
        };
        
        # Formatter
        formatter = pkgs.nixfmt;
        
        # Checks
        checks = {
          # Can add validation checks here
        };
      };
      
      # System configurations (not per-system)
      flake = {
        # Reusable modules
        nixosModules = {
          sops = inputs.sops-nix.nixosModules.sops;
          stylix = inputs.stylix.nixosModules.stylix;
        };
        
        homeManagerModules = {
          sops = inputs.sops-nix.homeManagerModules.sops;
          stylix = inputs.stylix.homeModules.stylix;
        };
        
        # NixOS configurations
        nixosConfigurations = {
          framework-16 = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ../hosts/framework-16/configuration.nix
              inputs.determinate.nixosModules.default
              inputs.sops-nix.nixosModules.sops
              inputs.stylix.nixosModules.stylix
            ];
          };
        };
        
        # Darwin configurations
        darwinConfigurations = {
          Zs-MacBook-Pro = inputs.nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ../hosts/mac-m1-max/configuration.nix
              inputs.sops-nix.darwinModules.sops
              inputs.stylix.homeModules.stylix  # stylix works via HM
            ];
          };
        };
        
        # Home Manager configurations
        homeConfigurations = {
          "zshen@framework-16" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            modules = [
              ../hosts/framework-16/home.nix
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          };
          "zshen@Zs-MacBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
            modules = [
              ../hosts/mac-m1-max/home.nix
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          };
        };
        
        # Templates
        templates = {
          java8 = {
            path = ../templates/java8;
            description = "Java 8 development environment";
          };
          nodejs22 = {
            path = ../templates/nodejs22;
            description = "Node.js 22 development environment";
          };
        };
      };
    };
}
```

## Flake Modules

### modules/flake/default.nix

```nix
# Main flake module that imports and configures helpers
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
        default = ["framework-16" "mac-m1-max"];
        description = "List of host names";
      };
    };
  };
}
```

### modules/flake/nixos.nix

```nix
# Helper for creating NixOS configurations
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

### modules/flake/darwin.nix

```nix
# Helper for creating Darwin configurations
{ inputs, config, lib, ... }: {
  options = myFlake.darwin = {
    createHost = lib.mkOption {
      type = lib.types.functionTo lib.types.anythings;
      description = "Create a Darwin host configuration";
    };
  };
  
  config = {
    myFlake.darwin.createHost = hostName: args:
      inputs.nix-darwin.lib.darwinSystem (args // {
        system = args.system or "aarch64-darwin";
        modules = [
          ../hosts/${hostName}/configuration.nix
          inputs.sops-nix.darwinModules.sops
        ] ++ (args.modules or []);
      });
  };
}
```

### modules/flake/home.nix

```nix
# Helper for creating Home Manager configurations
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
        pkgs = args.pkgs or (inputs.nixpkgs.legacyPackages.${args.system or "x86_64-linux"});
        modules = [
          ../hosts/${args.host}/home.nix
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
        ] ++ (args.modules or []);
      };
  };
}
```

## Partition Strategy

```nix
# For large flake, use partitions for lazy evaluation
partitions = {
  dev = {
    devShells.default = true;
    formatter = true;
    checks = true;
  };
  
  packages = {
    packages = true;
  };
  
  systems = {
    nixosConfigurations = true;
    darwinConfigurations = true;
    homeConfigurations = true;
  };
};

partitionedAttrs = {
  checks = "dev";
  devShells = "dev";
  formatter = "dev";
  packages = "packages";
  nixosConfigurations = "systems";
  darwinConfigurations = "systems";
  homeConfigurations = "systems";
};
```

## Benefits of Target Structure

| Aspect | Before | After |
|--------|--------|-------|
| **Code Volume** | ~175 lines | ~120 lines |
| **Boilerplate** | Manual forAllSystems | Built-in perSystem |
| **Multi-System** | Manual handling | Automatic |
| **Modularity** | Imports only | Full module system |
| **Reusability** | None | Export modules |
| **Lazy Eval** | None | Partitions |
| **Dev Experience** | Basic | devShells, formatter, checks |

## Migration Steps

1. **Add flake-parts input** (no output changes yet)
2. **Create flake modules** in `modules/flake/`
3. **Test basic evaluation** with flake-parts
4. **Migrate perSystem outputs** (packages, devShells)
5. **Migrate system configurations** (nixos, darwin, home)
6. **Add partitions** for lazy evaluation
7. **Add checks and formatter**
8. **Clean up old patterns**
9. **Update documentation**

## Rollback Plan

If migration fails:

1. Keep backup of original `flake.nix`
2. Use `git diff` to track changes
3. Test at each step
4. Can always return to:
   ```nix
   outputs = { ... }: {
     # Original structure
   };
   ```
