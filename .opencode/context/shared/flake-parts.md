# Flake-Parts Module System

Comprehensive guide to using flake-parts for modular flake organization.

## Overview

Flake-parts is a Nix library that applies the NixOS module system to flakes, providing:

- **Modular flake structure** using module system
- **Multi-system builds** via perSystem submodules
- **Lazy evaluation** via partitions
- **Cleaner output definitions**

## Basic Structure

### Importing Flake-Parts

```nix
{
  description = "My flake with flake-parts";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      # Configuration goes here
    };
}
```

### Complete Example

```nix
{
  description = "Nixos config flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      imports = [
        # Import reusable modules
        ./modules/flake/homemanager.nix
        ./modules/flake/nixos.nix
      ];
      
      # Optional: debug mode
      debug = true;
      
      # Define supported systems
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      
      # Per-system outputs
      perSystem = { config, self', pkgs, lib, ... }: {
        # Packages available on all systems
        packages = {
          hello = pkgs.hello;
          neovim = pkgs.neovim;
        };
        
        # Development shells
        devShells = {
          default = pkgs.mkShell {
            name = "development";
            packages = with pkgs; [
              git
              neovim
              nixfmt
            ];
          };
        };
        
        # Formatter
        formatter = pkgs.nixfmt;
      };
      
      # Flake-level outputs (not per-system)
      flake = {
        nixosConfigurations = {
          hostname = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./hosts/hostname/configuration.nix
            ];
          };
        };
        
        homeConfigurations = {
          "user@hostname" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            modules = [
              ./hosts/hostname/home.nix
            ];
          };
        };
      };
    };
}
```

## Core Options

### Global Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `imports` | list | `[]` | Modules to import |
| `debug` | boolean | `false` | Enable debug mode |
| `systems` | list | multi | List of supported systems |
| `perSystem` | function | `{}` | Per-system output configuration |
| `flake` | attrset | `{}` | Flake-level outputs |
| `partitions` | attrset | `{}` | Lazy evaluation groups |
| `partitionedAttrs` | attrset | `{}` | Map attrs to partitions |

### PerSystem Options

The `perSystem` function receives:

```nix
perSystem = { config, self', pkgs, lib, system, inputs, ... }: {
  # config: Current perSystem config (merged)
  # self': Same as perSystem result for this system
  # pkgs: nixpkgs for this system
  # lib: nixpkgs lib
  # system: Current system string
  
  packages = {
    # Package definitions
  };
  
  devShells = {
    # Development shell definitions
  };
  
  formatter = pkgs.nixfmt;
  
  checks = {
    # Derivation checks
  };
}
```

### Available PerSystem Outputs

| Output | Type | Description |
|--------|------|-------------|
| `packages` | attrset | Packages available via `nix build .#<name>` |
| `devShells` | attrset | Development shells via `nix develop` |
| `formatter` | package | Code formatter |
| `checks` | attrset | Checks via `nix flake check` |
| `apps` | attrset | Apps via `nix run .#<name>` |
| `bundlers` | attrset | Custom bundlers |
| `overlays` | list | Overlay functions |
| `legacyPackages` | attrset | Legacy package sets |

## Flake Outputs with Flake-Parts

### NixOS Configurations

```nix
flake = {
  nixosConfigurations = {
    hostname = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/hostname/configuration.nix
        # ... other modules
      ];
    };
  };
};
```

### Darwin Configurations

```nix
flake = {
  darwinConfigurations = {
    hostname = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/hostname/configuration.nix
      ];
    };
  };
};
```

### Home Manager Configurations

```nix
flake = {
  homeConfigurations = {
    "user@hostname" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./hosts/hostname/home.nix
      ];
    };
  };
};
```

### Reusable Modules

Export modules for reuse:

```nix
flake = {
  nixosModules = {
    my-module = ./modules/nixos/my-module.nix;
  };
  
  homeManagerModules = {
    my-module = ./modules/home-manager/my-module.nix;
  };
  
  flakeModules = {
    my-flake-module = ./modules/flake/my-flake-module.nix;
  };
};
```

Then import elsewhere:

```nix
outputs = inputs:
  inputs.flake-parts.flakeModules.flake-parts {
    imports = [
      # Import reusable modules
      inputs.self.outputs.nixosModules.my-module
    ];
  };
```

## PerSystem Patterns

### Basic Package

```nix
perSystem = { pkgs, ... }: {
  packages = {
    my-package = pkgs.hello;
  };
};
```

### Conditional Package (Linux only)

```nix
perSystem = { pkgs, system, ... }:
  let
    isLinux = pkgs.stdenv.isLinux;
  in {
    packages = pkgs.lib.optionalAttrs isLinux {
      helium = pkgs.callPackage ../packages/helium.nix {};
    };
  };
```

### Development Shell

```nix
perSystem = { pkgs, ... }: {
  devShells = {
    default = pkgs.mkShell {
      name = "development";
      packages = with pkgs; [
        git
        neovim
        nix-instantiate
      ];
      
      shellHook = ''
        export EDITOR=nvim
      '';
    };
    
    rust = pkgs.mkShell {
      name = "rust-development";
      packages = with pkgs; [
        rustc
        cargo
        rust-analyzer
      ];
    };
  };
};
```

### Formatter

```nix
perSystem = { pkgs, ... }: {
  formatter = pkgs.nixfmt;
};
```

### Checks

```nix
perSystem = { pkgs, ... }: {
  checks = {
    # Run a simple test
    test = pkgs.runCommand "test" {
      passAsFile = ["out"];
    } ''
      echo "All checks passed" > $out
    '';
    
    # Check that packages build
    build-packages = pkgs.linkFarm "build-packages" [
      { name = "hello"; path = pkgs.hello; }
    ];
  };
};
```

## Partitions for Lazy Evaluation

Partitions allow grouping outputs for lazy evaluation:

```nix
partitions = {
  dev = {
    devShells.default = true;
    formatter = true;
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

Usage:

```bash
# Only evaluate dev partition
nix flake metadata . --partitions dev

# Evaluate specific attrs in partition
nix develop . --partitions dev
```

## Modules

### Creating Flake Modules

Create reusable modules for flake-parts:

```nix
# modules/flake/my-module.nix
{ inputs, config, lib, ... }: {
  # Options
  options = with lib; {
    myModule = {
      enable = mkEnableOption "my module";
      package = mkOption {
        type = types.package;
        default = pkgs.hello;
      };
    };
  };
  
  # Config
  config = lib.mkIf config.myModule.enable {
    perSystem = _: {
      packages = {
        my-module = config.myModule.package;
      };
    };
  };
}
```

### Importing Custom Modules

```nix
outputs = inputs:
  inputs.flake-parts.flakeModules.flake-parts {
    imports = [
      ./modules/flake/my-module.nix
    ];
    
    # Configure the module
    myModule = {
      enable = true;
      package = inputs.nixpkgs.legacyPackages.x86_64-linux.vim;
    };
  };
```

## Comparison: Traditional vs Flake-Parts

### Traditional Flake

```nix
{
  inputs = { nixpkgs.url = "..."; };
  
  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux" "aarch64-darwin"
      ];
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          hello = pkgs.hello;
        }
      );
      
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ git ];
          };
        }
      );
    };
}
```

### Flake-Parts

```nix
{
  inputs = {
    nixpkgs.url = "...";
    flake-parts.url = "...";
  };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      
      perSystem = { pkgs, ... }: {
        packages = {
          hello = pkgs.hello;
        };
        
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [ git ];
          };
        };
      };
    };
}
```

**Benefits of Flake-Parts**:
- Less boilerplate (no `forAllSystems` manually)
- Module system for outputs
- Cleaner perSystem configuration
- Built-in multi-system support
- Partitions for lazy evaluation

## Migration from Traditional Flake

### Step 1: Add flake-parts input

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-parts.url = "github:hercules-ci/flake-parts";
};
```

### Step 2: Restructure outputs

```nix
# Before
outputs = { self, nixpkgs }: {
  packages = ...;
};

# After
outputs = inputs:
  inputs.flake-parts.flakeModules.flake-parts {
    perSystem = ...;
    flake = {
      # Move nixosConfigurations, etc. here
    };
  };
```

### Step 3: Simplify perSystem

```nix
# Before (with forAllSystems)
packages = nixpkgs.lib.genAttrs systems (system:
  let pkgs = import nixpkgs { inherit system; };
  in { hello = pkgs.hello; }
);

# After (direct perSystem)
perSystem = { pkgs, ... }: {
  packages = {
    hello = pkgs.hello;
  };
};
```

## Best Practices

1. **Use perSystem for system-specific outputs**
2. **Use flake for system-independent outputs**
3. **Use partitions for large flakes to speed up evaluation**
4. **Export reusable modules via nixosModules, homeManagerModules**
5. **Keep perSystem function pure and focused**
6. **Use imports for modular flake structure**
7. **Set `systems` explicitly for clarity**
8. **Use `optionalAttrs` for conditional packages**

## Common Issues

### "error: flake-parts not found"

Ensure flake-parts is in inputs:

```nix
inputs = {
  flake-parts.url = "github:hercules-ci/flake-parts";
};
```

### PerSystem not receiving expected arguments

The perSystem function receives these arguments by default:
- `config`: Merged perSystem config
- `self'`: This system's outputs
- `pkgs`: nixpkgs for this system
- `lib`: nixpkgs lib
- `system`: Current system string
- `inputs`: All flake inputs
- `inputsSelf`: Self reference

### Packages not appearing

Make sure packages are in the `packages` attribute:

```nix
perSystem = { pkgs, ... }: {
  packages = {
    # Must be named, not just assigned
    my-package = pkgs.hello;  # Correct
  };
  # Not: perSystem = pkgs.hello;  // Wrong
};
```
