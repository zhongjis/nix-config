# New Module Workflow

Workflow for creating new Nix modules for the nix-config repository.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    New Module Workflow                       │
├─────────────────────────────────────────────────────────────┤
│  1. Plan Module                                               │
│     → Define purpose, options, dependencies                   │
│  2. Create Scaffold                                           │
│     → Create module file with basic structure                 │
│  3. Implement Options                                         │
│     → Define module options and their types                   │
│  4. Implement Configuration                                   │
│     → Define how options translate to config                  │
│  5. Add to Host                                               │
│     → Import module in appropriate host                       │
│  6. Test                                                      │
│     → Validate syntax and imports                             │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Plan Module

### Determine Module Type

| Type | Location | Purpose |
|------|----------|---------|
| **Shared HM Feature** | `modules/shared/home-manager/features/<name>/` | User-level program/service |
| **NixOS Feature** | `modules/nixos/features/<name>/` | System-level service |
| **NixOS Bundle** | `modules/nixos/bundles/<name>/` | Desktop environment bundle |
| **Shared Utility** | `modules/shared/<name>.nix` | Cross-platform utility |
| **Host-Specific** | `hosts/<host>/<name>.nix` | Machine-specific config |

### Define Module Structure

```nix
# Example: modules/nixos/features/my-feature/default.nix
{ pkgs, inputs, lib, config, ... }:

with lib; {
  options = myNixOS.features.my-feature = {
    enable = mkEnableOption "my feature";
    
    # Additional options
    package = mkOption {
      type = types.package;
      default = pkgs.my-package;
      description = "Package to use";
    };
    
    setting = mkOption {
      type = types.str;
      default = "default";
      description = "Configuration setting";
    };
  };
  
  config = mkIf config.myNixOS.features.my-feature.enable {
    # Configuration goes here
    environment.systemPackages = [ config.myNixOS.features.my-feature.package ];
    
    services.my-service = {
      enable = true;
      setting = config.myNixOS.features.my-feature.setting;
    };
  };
}
```

### Check Dependencies

```nix
# Required inputs?
inputs? 
  nixpkgs
  home-manager
  sops-nix
  etc.

# Required modules?
imports = [
  # Dependencies on other modules
];
```

## Step 2: Create Scaffold

### Create Directory Structure

```bash
# For a new NixOS feature
mkdir -p modules/nixos/features/my-feature

# For a new HM feature
mkdir -p modules/shared/home-manager/features/my-feature
```

### Create Module File

```nix
# modules/nixos/features/my-feature/default.nix
{ pkgs, inputs, lib, config, ... }:

let
  cfg = config.myNixOS.features.my-feature;
in

{
  # Meta
  meta.maintainers = ["zshen"];
  
  # Imports
  imports = [
    # Other modules this depends on
  ];
  
  # Options
  options = myNixOS.features.my-feature = {
    enable = lib.mkEnableOption "my feature";
    
    # Add more options as needed
  };
  
  # Configuration
  config = lib.mkIf cfg.enable {
    # Your configuration here
  };
}
```

### Create Feature Bundle (if needed)

```nix
# modules/nixos/bundles/my-bundle.nix
{ config, lib, ... }:

let
  cfg = config.myNixOS.bundles.my-bundle;
in

{
  imports = [
    # Import features in this bundle
    ../features/feature1.nix
    ../features/feature2.nix
  ];
  
  options = myNixOS.bundles.my-bundle = {
    enable = lib.mkEnableOption "my bundle";
  };
  
  config = lib.mkIf cfg.enable {
    # Enable all features in bundle
    myNixOS.features.feature1.enable = true;
    myNixOS.features.feature2.enable = true;
  };
}
```

## Step 3: Implement Options

### Common Option Types

```nix
# Boolean
enable = mkEnableOption "my feature";

# String
setting = mkOption {
  type = types.str;
  default = "default";
  description = "Description of setting";
};

# Integer
port = mkOption {
  type = types.int;
  default = 8080;
  description = "Port number";
};

# Package
package = mkOption {
  type = types.package;
  default = pkgs.default-package;
  description = "Package to use";
};

# List
packages = mkOption {
  type = types.listOf types.package;
  default = [];
  description = "List of packages";
};

# Enum
mode = mkOption {
  type = types.enum ["mode1" "mode2" "mode3"];
  default = "mode1";
  description = "Operation mode";
};

# Attribute Set
settings = mkOption {
  type = types.attrsOf types.str;
  default = {};
  description = "Settings as key-value pairs";
};
```

### Option Groups

```nix
options = myModule = {
  enable = mkEnableOption "my module";
  
  # Group related options
  service = {
    enable = mkEnableOption "service component";
    port = mkOption { ... };
  };
  
  package = {
    enable = mkEnableOption "package component";
    extraPackages = mkOption { ... };
  };
};
```

## Step 4: Implement Configuration

### Using Options

```nix
config = mkIf cfg.enable {
  # Simple usage
  environment.systemPackages = [ cfg.package ];
  
  # Conditional
  services.my-service = mkIf cfg.service.enable {
    port = cfg.service.port;
  };
  
  # List comprehension
  home.packages = map (p: pkgs.${p}) cfg.package.extraPackages;
  
  # Merge attributes
  systemd.services.my-service = mkMerge [
    {
      WantedBy = ["multi-user.target"];
    }
    (mkIf cfg.service.enable {
      Service = {
        ExecStart = "${cfg.package}/bin/my-service --port ${toString cfg.service.port}";
      };
    })
  ];
}
```

### Helper Functions

```nix
# Common patterns
mkIf cfg.enable { ... }           # Conditional
mkWhen cfg.enable { ... }         # Conditional (lazy)
mkDefault true                    # Set default
mkForce "value"                   # Override
optionalAttrs cfg.enable { ... }  # Conditionally add attrs
```

## Step 5: Add to Host

### Import in Host Configuration

```nix
# hosts/framework-16/configuration.nix
{
  imports = [
    ../../modules/shared
    ../../modules/nixos
    # Add your module
    ../../modules/nixos/features/my-feature
  ];
  
  myNixOS = {
    # Existing features
    bundles.general-desktop.enable = true;
    
    # Add your feature
    features.my-feature.enable = true;
    features.my-feature.setting = "custom";
  };
}
```

### Export from Shared Module

```nix
# modules/shared/default.nix
# Import all modules in this directory
[
  ./home-manager
  ./cachix.nix
  # Your module will be imported here
]
```

### For Feature Directories

```nix
# modules/shared/home-manager/features/my-feature/default.nix
{ pkgs, lib, config, ... }:

let
  cfg = config.myhm.features.my-feature;
in

{
  options = myhm.features.my-feature = {
    enable = lib.mkEnableOption "my feature";
    setting = lib.mkOption { ... };
  };
  
  config = lib.mkIf cfg.enable {
    # Home Manager configuration
    programs.my-feature.enable = true;
  };
}
```

## Step 6: Test

### Syntax Check

```bash
# Check module syntax
nix-instantiate --parse modules/nixos/features/my-feature/default.nix

# Check module evaluation
nix-instantiate --eval -E 'let
  mod = import ./modules/nixos/features/my-feature/default.nix { 
    pkgs = import <nixpkgs> {};
    lib = (import <nixpkgs> {}).lib;
    config = { myNixOS.features.my-feature.enable = true; };
    options = {};
  };
in mod.config or "OK"'
```

### Import Check

```bash
# Test import in host
nix-instantiate --eval -E '
  let
    flake = import ./flake.nix {};
  in
    builtins.attrNames flake.nixosConfigurations
'
```

### Full Build Test

```bash
# Test NixOS build
nh os switch . --dry-run

# Test specific module
nix eval .#nixosConfigurations.framework-16.config.myNixOS.features.my-feature.enable
```

### Import Chain Validation

```bash
# Check for circular imports
/check-modules --module modules/nixos/features/my-feature --imports
```

## Example: Creating a Kubernetes Module

```nix
# modules/nixos/features/kubernetes/default.nix
{ pkgs, lib, config, ... }:

let
  cfg = config.myNixOS.features.kubernetes;
in

{
  meta.maintainers = with lib.maintainers; [ "zshen" ];
  
  options = myNixOS.features.kubernetes = {
    enable = lib.mkEnableOption "Kubernetes";
    
    enableK3s = lib.mkEnableOption "K3s lightweight Kubernetes";
    k3sChannel = lib.mkOption {
      type = lib.types.str;
      default = "stable";
      example = "v1.28";
      description = "K3s channel";
    };
    
    enableNixKube = lib.mkEnableOption "nix-kube";
    kubeconfigPath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/kubernetes/admin.conf";
      description = "Kubeconfig location";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # K3s
    services.k3s = lib.mkIf cfg.enableK3s {
      enable = true;
      channel = cfg.k3sChannel;
      extraFlags = "--disable traefik";
    };
    
    # nix-kube
    environment.systemPackages = lib.mkIf cfg.enableNixKube (
      with pkgs; [ nix-kube ]
    );
    
    # kubectl completion
    programs.kubernetes = {
      enable = true;
      kubeconfig = cfg.kubeconfigPath;
    };
  };
}
```

## Best Practices

1. **Start with enable option** - All modules should have it
2. **Use mkEnableOption** - Consistent boolean options
3. **Provide sensible defaults** - Don't require user to set everything
4. **Document options** - Description is required
5. **Group related options** - Use sub-attributes
6. **Use mkIf/mkWhen** - Avoid runtime conditionals
7. **Test imports** - Verify module works with imports
8. **Follow naming conventions** - Consistent with project patterns
