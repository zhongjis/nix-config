# Flake-Parts Patterns

Common patterns and conventions for using flake-parts in the nix-config repository.

## Basic Flake-Parts Setup

### Minimal Example

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      perSystem = { pkgs, ... }: {
        packages = {
          hello = pkgs.hello;
        };
      };
    };
}
```

### Full Example

```nix
{
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
        ./modules/flake/default.nix
      ];
      
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      
      perSystem = { config, self', pkgs, lib, system, inputs, ... }: {
        packages = {
          hello = pkgs.hello;
        };
        
        devShells = {
          default = pkgs.mkShell {
            name = "dev";
            packages = with pkgs; [ git ];
          };
        };
        
        formatter = pkgs.nixfmt;
      };
      
      flake = {
        nixosConfigurations = {
          hostname = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./hosts/hostname/configuration.nix ];
          };
        };
        
        homeConfigurations = {
          "user@hostname" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            modules = [ ./hosts/hostname/home.nix ];
          };
        };
      };
    };
}
```

## PerSystem Patterns

### Basic Pattern

```nix
perSystem = { pkgs, lib, ... }: {
  packages = {
    package-name = pkgs.package-name;
  };
  
  devShells = {
    default = pkgs.mkShell { ... };
  };
  
  formatter = pkgs.nixfmt;
};
```

### Conditional Packages

```nix
perSystem = { pkgs, lib, system, ... }:
  let
    isLinux = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
  in {
    packages = {
      # Available on all systems
      hello = pkgs.hello;
      
      # Linux only
    } // lib.optionalAttrs isLinux {
      linux-tool = pkgs.linuxTool;
    } // lib.optionalAttrs isDarwin {
      darwin-tool = pkgs.darwinTool;
    };
    
    devShells = {
      default = pkgs.mkShell { ... };
    };
  };
```

### Using config

```nix
perSystem = { config, pkgs, ... }: {
  # Use merged config
  packages = {
    my-package = config.myPackage or pkgs.hello;
  };
};
```

### Using self'

```nix
perSystem = { self', pkgs, ... }: {
  # Reference this system's packages
  packages = {
    main = self'.packages.hello;
    wrapper = pkgs.writeShellScriptBin "hello-wrapper" ''
      ${self'.packages.hello}/bin/hello "$@"
    '';
  };
};
```

## Flake Output Patterns

### System Configurations

```nix
flake = {
  nixosConfigurations = {
    hostname = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/hostname/configuration.nix
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
      ];
    };
  };
  
  darwinConfigurations = {
    hostname = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
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
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/hostname/home.nix
        inputs.sops-nix.homeManagerModules.sops
        inputs.stylix.homeModules.stylix
      ];
    };
  };
};
```

### Exporting Modules

```nix
flake = {
  nixosModules = {
    my-module = ./modules/nixos/my-module.nix;
    sops = inputs.sops-nix.nixosModules.sops;
  };
  
  homeManagerModules = {
    my-module = ./modules/home-manager/my-module.nix;
    sops = inputs.sops-nix.homeManagerModules.sops;
  };
  
  flakeModules = {
    my-flake-module = ./modules/flake/my-flake-module.nix;
  };
};
```

## Partition Patterns

### Basic Partitions

```nix
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
  devShells = "dev";
  formatter = "dev";
  checks = "dev";
  packages = "packages";
  nixosConfigurations = "systems";
  darwinConfigurations = "systems";
  homeConfigurations = "systems";
};
```

### Usage

```bash
# Only evaluate dev partition
nix develop . --partitions dev

# Evaluate specific attrs
nix flake metadata . --partitions packages
```

## Import Patterns

### Flake Module Imports

```nix
# In modules/flake/default.nix
{ inputs, config, lib, ... }: {
  imports = [
    ./nixos.nix
    ./darwin.nix
    ./home.nix
  ];
  
  options = {
    myFlake.hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["framework-16" "mac-m1-max"];
    };
  };
}
```

### System Config Imports

```nix
# In hosts/hostname/configuration.nix
{ config, lib, inputs, ... }: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix
    ../../modules/nixos/features/feature1.nix
    ../../modules/nixos/features/feature2.nix
  ];
  
  # ... configuration
}
```

## Error Handling Patterns

### Safe Evaluation

```nix
perSystem = { pkgs, ... }: {
  packages = {
    # Use tryEval for potentially failing builds
    my-package = pkgs.lib.warnIf (builtins.hasAttr "fail" pkgs)
      "my-package has issues"
      (pkgs.my-package or pkgs.hello);
  };
};
```

### Fallback Packages

```nix
perSystem = { pkgs, ... }: {
  packages = {
    my-tool = pkgs.my-tool or (pkgs.writeShellScriptBin "my-tool" ''
      echo "my-tool not available on this platform"
    '');
  };
};
```

## Performance Patterns

### Lazy Evaluation

```nix
# Partition slow evaluations
partitions = {
  dev = {
    devShells.default = true;
    formatter = true;
  };
  
  heavy = {
    packages = true;
    checks = true;
  };
};
```

### Conditional Loading

```nix
perSystem = { pkgs, system, ... }: {
  # Only load heavy tools when needed
  devShells = {
    default = pkgs.mkShell {
      name = "dev";
      packages = with pkgs; [ git ];
    };
    
    rust = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
      pkgs.mkShell {
        name = "rust-dev";
        packages = with pkgs; [ rustc cargo ];
      };
    };
  };
};
```

## Common Patterns

### Multi-System Package

```nix
perSystem = { pkgs, ... }: {
  packages = {
    neovim = (import ../modules/shared/home-manager/features/neovim/nvf {
      inherit pkgs;
    }).neovim;
  };
};
```

### Template Definition

```nix
flake = {
  templates = {
    my-template = {
      path = ./templates/my-template;
      description = "My development template";
      welcomeText = ''
        Welcome to my template!
        
        Run `nix develop` to get started.
      '';
    };
  };
};
```

### Checks

```nix
perSystem = { pkgs, ... }: {
  checks = {
    # Validation check
    format = pkgs.runCommand "format-check" {
      passAsFile = ["out"];
    } ''
      ${pkgs.nixfmt}/bin/nixfmt --check *.nix 2>&1 > $out || true
    '';
    
    # Build check
    build-packages = pkgs.linkFarm "build-check" [
      { name = "hello"; path = pkgs.hello; }
    ];
  };
};
```

## Migration Patterns

### From Traditional to Flake-Parts

```nix
# Before (traditional)
outputs = { self, nixpkgs }: let
  forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ... ];
in {
  packages = forAllSystems (system:
    let pkgs = import nixpkgs { inherit system; };
    in { hello = pkgs.hello; }
  );
};

# After (flake-parts)
outputs = inputs:
  inputs.flake-parts.flakeModules.flake-parts {
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    
    perSystem = { pkgs, ... }: {
      packages = {
        hello = pkgs.hello;
      };
    };
  };
```

### Hybrid Approach

```nix
outputs = inputs:
  inputs.flake-parts.flakeModules.flake-parts {
    # Use flake-parts for perSystem
    perSystem = { pkgs, ... }: {
      packages = {
        hello = pkgs.hello;
      };
    };
    
    # Keep traditional for complex configs
    flake = {
      nixosConfigurations = {
        # Complex config, keep traditional
        hostname = (import ./lib.nix { inherit inputs; }).mkSystem "hostname" { ... };
      };
    };
  };
```
