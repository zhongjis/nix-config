# Flake-Parts Migration Workflow

Complete workflow for migrating the nix-config repository to use flake-parts.

## Overview

This workflow guides you through migrating from the traditional flake structure to flake-parts, with 5 phases over approximately 5 weeks.

## Prerequisites

Before starting:

```bash
# 1. Ensure current config works
/validate-config --full

# 2. Commit any pending changes
git add -A && git commit -m "Pre-migration checkpoint"

# 3. Backup current flake.nix
cp flake.nix flake.nix.backup

# 4. Notify users of migration
echo "Migration starting soon"
```

## Phase 1: Infrastructure (Week 1)

### Goals
- Add flake-parts input
- Create modules/flake/ directory structure
- Create basic flake modules
- Test evaluation with flake-parts

### Steps

```bash
# 1. Add flake-parts input
# Edit flake.nix, add:
# flake-parts.url = "github:hercules-ci/flake-parts";

# 2. Create modules/flake/
mkdir -p modules/flake
touch modules/flake/default.nix
touch modules/flake/nixos.nix
touch modules/flake/darwin.nix
touch modules/flake/home.nix

# 3. Create basic flake module
# See context/domain/target-structure.md for template

# 4. Test evaluation
nix eval .#packages.x86_64-linux.hello --no-link

# 5. Validate
/validate-config --full
```

### Validation

- [ ] flake.nix evaluates
- [ ] All inputs resolve
- [ ] Packages still build
- [ ] No regressions

## Phase 2: Core Migration (Week 2)

### Goals
- Migrate nixosConfigurations
- Migrate darwinConfigurations
- Migrate homeConfigurations
- Test all hosts

### Steps

```bash
# 1. Migrate NixOS config
# Edit flake.nix, replace mkSystem with:
# nixosConfigurations.hostname = inputs.nixpkgs.lib.nixosSystem {
#   system = "x86_64-linux";
#   specialArgs = { inherit inputs; };
#   modules = [ ./hosts/hostname/configuration.nix ... ];
# };

# 2. Migrate Darwin config
# Similar pattern for darwinConfigurations

# 3. Migrate Home Manager
# Similar pattern for homeConfigurations

# 4. Test all hosts
/validate-config --full
```

### Validation

- [ ] framework-16 evaluates
- [ ] Zs-MacBook-Pro evaluates
- [ ] All HM profiles evaluate
- [ ] Dry-run switches work

## Phase 3: Package Migration (Week 3)

### Goals
- Migrate packages to perSystem
- Add devShells
- Add formatter and checks
- Test packages

### Steps

```bash
# 1. Migrate packages to perSystem
# In flake.nix outputs:
# perSystem = { pkgs, ... }: {
#   packages = {
#     neovim = ...;
#   } // lib.optionalAttrs pkgs.stdenv.isLinux {
#     helium = import ./packages/helium.nix { inherit pkgs; };
#   };
# };

# 2. Add devShells
perSystem = { pkgs, ... }: {
  devShells = {
    default = pkgs.mkShell {
      name = "nix-config-dev";
      packages = with pkgs; [ nix-tree nix-diff ];
    };
  };
};

# 3. Add formatter
perSystem = { pkgs, ... }: {
  formatter = pkgs.nixfmt;
};

# 4. Add checks
perSystem = { pkgs, ... }: {
  checks = {
    format = pkgs.runCommand "format-check" { ... };
  };
};

# 5. Test packages
nix build .#packages.*
```

### Validation

- [ ] All packages build
- [ ] devShells work: `nix develop`
- [ ] Formatter works: `nix fmt`
- [ ] Checks work: `nix flake check`

## Phase 4: Module Refactoring (Week 4)

### Goals
- Consolidate duplicate patterns
- Improve lib/default.nix
- Standardize module structure

### Steps

```bash
# 1. Analyze current structure
/refactor-modules --analyze

# 2. Find duplicates
/refactor-modules --duplicates

# 3. Apply consolidations
/refactor-modules --apply consolidation --dry-run
/refactor-modules --apply consolidation  # If happy

# 4. Improve lib
# Add flake-parts helpers to lib/default.nix

# 5. Standardize modules
/check-modules --fix
```

### Validation

- [ ] No duplicate patterns
- [ ] lib/default.nix enhanced
- [ ] Quality score improved
- [ ] All modules validate

## Phase 5: Cleanup (Week 5)

### Goals
- Remove old patterns
- Update documentation
- Final validation
- Complete migration

### Steps

```bash
# 1. Remove old patterns
# Remove forAllSystems usage
# Remove verbose optionalAttrs patterns

# 2. Update documentation
# Update README with new commands
# Document new patterns

# 3. Final validation
/validate-config --full

# 4. Test all commands
/flake-analyze
/switch-host framework-16 --dry-run
/new-module test nixos/features  # Verify creation

# 5. Commit migration
git add -A
git commit -m "flake: migrate to flake-parts

Complete migration to flake-parts module system.

Changes:
- Added flake-parts input and modules
- Migrated system configurations to flake-parts
- Added perSystem for packages, devShells, checks
- Consolidated duplicate patterns
- Improved lib/default.nix

See context/domain/target-structure.md for details."
```

### Final Validation Checklist

- [ ] flake.nix evaluates
- [ ] All packages build
- [ ] All hosts configure
- [ ] All commands work
- [ ] Documentation updated
- [ ] No regressions

## Rollback Plan

If something goes wrong:

```bash
# Option 1: Revert to backup
cp flake.nix.backup flake.nix
git checkout -- .
nix flake lock

# Option 2: Revert commit
git revert HEAD
git revert HEAD~1  # etc

# Option 3: Git stash
git stash
git stash pop
```

## Timeline

| Phase | Duration | Effort | Risk |
|-------|----------|--------|------|
| 1: Infrastructure | 1 week | Low | Low |
| 2: Core | 1 week | Medium | Medium |
| 3: Packages | 1 week | Low | Low |
| 4: Refactoring | 1 week | Medium | Medium |
| 5: Cleanup | 1 week | Low | Low |

**Total: ~5 weeks**

## Benefits After Migration

- **Cleaner code**: 30% less boilerplate
- **Better organization**: Module system for flake
- **Multi-system**: Automatic perSystem
- **Lazy evaluation**: Partitions support
- **Reusable**: Export modules easily
