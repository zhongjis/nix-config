# Refactoring Workflow

Workflow for refactoring the nix-config repository, including migration to flake-parts.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Refactoring Workflow                       │
├─────────────────────────────────────────────────────────────┤
│  1. Analyze Current Structure                                │
│     → Identify issues, duplication, organization problems    │
│  2. Plan Refactoring                                         │
│     → Design target structure, create migration plan         │
│  3. Phase 1: Infrastructure                                  │
│     → Add flake-parts, create module structure               │
│  4. Phase 2: Core Migration                                  │
│     → Migrate system configurations                          │
│  5. Phase 3: Package Migration                               │
│     → Migrate packages to perSystem                          │
│  6. Phase 4: Module Refactoring                              │
│     → Consolidate duplicates, improve patterns               │
│  7. Phase 5: Cleanup                                         │
│     → Remove old patterns, update docs                       │
│  8. Validate                                                 │
│     → Test all configurations, verify functionality          │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Analyze Current Structure

### Run Analysis

```bash
# Analyze flake structure
/flake-analyze --detailed

# Check module organization
/check-modules --analyze

# Check for duplicates
/refactor-modules --duplicates

# Check consistency
/refactor-modules --consistency
```

### Document Issues

```markdown
# Refactoring Analysis Report

## Structure Score
- flake.nix: 5/10
- modules/: 7/10
- lib/: 5/10
- packages/: 8/10
- hosts/: 9/10

## Issues Found

### Critical
1. flake.nix lacks modularity
2. No flake-parts integration
3. No perSystem pattern

### Major
1. Some module duplication
2. Inconsistent option patterns
3. Limited lib helpers

### Minor
1. Some documentation missing
2. Minor naming inconsistencies
```

## Step 2: Plan Refactoring

### Design Target Structure

```nix
# Target flake-parts structure
{
  inputs = {
    nixpkgs.url = "...";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # ... other inputs
  };
  
  outputs = inputs:
    inputs.flake-parts.flakeModules.flake-parts {
      imports = [
        ./modules/flake/default.nix
      ];
      
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      
      perSystem = { pkgs, ... }: {
        packages = { /* ... */ };
        devShells = { /* ... */ };
      };
      
      flake = {
        nixosConfigurations = { /* ... */ };
        homeConfigurations = { /* ... */ };
      };
    };
}
```

### Create Migration Plan

```markdown
# Migration Plan

## Phase 1: Infrastructure (Week 1)
- [ ] Add flake-parts input
- [ ] Create modules/flake/ directory
- [ ] Create basic flake modules
- [ ] Test evaluation with flake-parts

## Phase 2: Core Migration (Week 2)
- [ ] Migrate nixosConfigurations
- [ ] Migrate darwinConfigurations
- [ ] Migrate homeConfigurations
- [ ] Test all hosts

## Phase 3: Package Migration (Week 3)
- [ ] Migrate packages to perSystem
- [ ] Add devShells
- [ ] Add formatter and checks
- [ ] Test packages

## Phase 4: Module Refactoring (Week 4)
- [ ] Consolidate duplicate patterns
- [ ] Improve lib/default.nix
- [ ] Standardize module structure
- [ ] Update documentation

## Phase 5: Cleanup (Week 5)
- [ ] Remove old patterns
- [ ] Update README
- [ ] Final validation
- [ ] Complete migration
```

## Step 3: Phase 1 - Infrastructure

### Add flake-parts Input

```nix
# In flake.nix inputs
flake-parts.url = "github:hercules-ci/flake-parts";
```

### Create Flake Modules

```bash
# Create directory
mkdir -p modules/flake

# Create modules
touch modules/flake/default.nix
touch modules/flake/nixos.nix
touch modules/flake/darwin.nix
touch modules/flake/home.nix
```

### Test Evaluation

```bash
# Test that flake evaluates
nix eval .#packages.x86_64-linux.hello --no-link

# Check flake-parts integration
nix flake show
```

## Step 4: Phase 2 - Core Migration

### Migrate NixOS Configurations

```nix
# Before
nixosConfigurations = {
  framework-16 = mkSystem "framework-16" {
    system = "x86_64-linux";
    # ...
  };
};

# After (in flake-parts)
flake = {
  nixosConfigurations = {
    framework-16 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/framework-16/configuration.nix
        inputs.determinate.nixosModules.default
        inputs.sops-nix.nixosModules.sops
      ];
    };
  };
};
```

### Migrate Home Manager

```nix
# After (in flake-parts)
flake = {
  homeConfigurations = {
    "zshen@framework-16" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./hosts/framework-16/home.nix
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
  };
};
```

### Test Hosts

```bash
# Test all hosts evaluate
nix eval .#nixosConfigurations.framework-16
nix eval .#darwinConfigurations.Zs-MacBook-Pro
nix eval .#homeConfigurations

# Dry run switch
nh os switch . --dry-run
```

## Step 5: Phase 3 - Package Migration

### Migrate to perSystem

```nix
# Before
packages = forAllSystems (pkgs: {
  neovim = ...;
} // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  helium = import ./packages/helium.nix { inherit pkgs; };
});

# After (perSystem)
perSystem = { pkgs, lib, ... }: {
  packages = {
    neovim = ...;
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    helium = pkgs.callPackage ../packages/helium.nix {};
  };
};
```

### Add devShells

```nix
perSystem = { pkgs, ... }: {
  devShells = {
    default = pkgs.mkShell {
      name = "nix-config-dev";
      packages = with pkgs; [ nix-tree nix-diff ];
    };
  };
};
```

### Test Packages

```bash
# Build all packages
nix build .#packages.*

# Test dev shell
nix develop
```

## Step 6: Phase 4 - Module Refactoring

### Consolidate Duplicates

```bash
# Find duplicates
/refactor-modules --duplicates

# Apply consolidation
/refactor-modules --apply consolidation
```

### Improve Lib

```nix
# lib/default.nix improvements
{
  # Add flake-parts helpers
  mkFlakeSystem = { system, modules, specialArgs ? {} }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = modules ++ [
        inputs.sops-nix.nixosModules.sops
      ];
    };
}
```

### Standardize Patterns

```nix
# Standard module structure
{ pkgs, inputs, lib, config, ... }:

let
  cfg = config.myModule.feature;
in

{
  meta.maintainers = with lib.maintainers; [ "zshen" ];
  
  options = myModule.feature = {
    enable = lib.mkEnableOption "feature";
    setting = lib.mkOption { ... };
  };
  
  config = lib.mkIf cfg.enable {
    # Configuration
  };
}
```

## Step 7: Phase 5 - Cleanup

### Remove Old Patterns

```bash
# Remove forAllSystems usage
# Remove manual per-system handling
# Remove verbose optionalAttrs patterns
```

### Update Documentation

```bash
# Update README
# Update comments in flake.nix
# Document new patterns
```

### Final Validation

```bash
# Full validation
/validate-config --full

# Test all hosts
/switch-host framework-16 --dry-run
/switch-host mac-m1-max --dry-run

# Build all packages
nix build .#packages.*
```

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
```

## Validation Checklist

- [ ] flake.nix evaluates
- [ ] All packages build
- [ ] All hosts configure (dry-run)
- [ ] No circular dependencies
- [ ] All imports resolve
- [ ] Documentation updated
- [ ] No regression in functionality

## Migration Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| 1: Infrastructure | 1 week | flake-parts setup |
| 2: Core | 1 week | System configs |
| 3: Packages | 1 week | perSystem, devShells |
| 4: Refactoring | 1 week | Module cleanup |
| 5: Cleanup | 1 week | Validation, docs |

**Total: 5 weeks**

## Best Practices

1. **Phase approach** - Do one thing at a time
2. **Test frequently** - Validate after each change
3. **Keep backup** - Revert if needed
4. **Document changes** - Track what changed
5. **Small commits** - Easy to bisect
6. **Dry runs first** - Test before applying
7. **Rollback plan** - Always have exit strategy
8. **Validate end-to-end** - Full testing at completion
