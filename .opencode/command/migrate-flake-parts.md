---
command: /migrate-flake-parts
description: Migrate the flake to use flake-parts module system
syntax: |
  /migrate-flake-parts [options]
options:
  - --dry-run: Show migration plan without executing
  - --phase <1-5>: Execute specific phase only
  - --test: Test after each step
  - --rollback: Rollback to previous state
examples:
  - "/migrate-flake-parts --dry-run"
  - "/migrate-flake-parts --phase 1"
  - "/migrate-flake-parts --test"
---

# Migrate Flake-Parts Command

Migrates the current flake to use flake-parts module system.

## Usage

```bash
/migrate-flake-parts --dry-run    # Preview migration
/migrate-flake-parts              # Execute full migration
/migrate-flake-parts --phase 1    # Only phase 1
/migrate-flake-parts --test       # Test after each step
/migrate-flake-parts --rollback   # Rollback changes
```

## Migration Phases

### Phase 1: Infrastructure
- Add flake-parts input
- Create modules/flake/ directory
- Create basic flake modules
- Test evaluation

### Phase 2: Core Migration
- Migrate nixosConfigurations
- Migrate darwinConfigurations
- Migrate homeConfigurations
- Test all hosts

### Phase 3: Package Migration
- Migrate packages to perSystem
- Add devShells
- Add formatter and checks
- Test packages

### Phase 4: Module Refactoring
- Consolidate duplicate patterns
- Improve lib/default.nix
- Standardize module structure

### Phase 5: Cleanup
- Remove old patterns
- Update documentation
- Final validation

## Examples

### Dry Run

```bash
$ /migrate-flake-parts --dry-run

=== Migration Plan ===

Phase 1: Infrastructure
[ ] Add flake-parts to inputs
[ ] Create modules/flake/default.nix
[ ] Create modules/flake/nixos.nix
[ ] Create modules/flake/darwin.nix
[ ] Create modules/flake/home.nix
[ ] Test evaluation

Phase 2: Core Migration
[ ] Migrate nixosConfigurations to flake-parts
[ ] Migrate darwinConfigurations
[ ] Migrate homeConfigurations
[ ] Test all hosts

Phase 3: Package Migration
[ ] Migrate packages to perSystem
[ ] Add devShells
[ ] Add formatter
[ ] Add checks
[ ] Test packages

Phase 4: Module Refactoring
[ ] Consolidate patterns
[ ] Improve lib
[ ] Standardize modules

Phase 5: Cleanup
[ ] Remove old code
[ ] Update docs
[ ] Final validation

Estimated time: 5 weeks (1 week per phase)
Risk: Medium (breaking change)

Run without --dry-run to execute
```

### Execute Migration

```bash
$ /migrate-flake-parts

=== Phase 1: Infrastructure ===

1. Adding flake-parts input...
✅ Added to flake.nix

2. Creating modules/flake/ directory...
✅ Created

3. Creating flake modules...
✅ Created default.nix
✅ Created nixos.nix
✅ Created darwin.nix
✅ Created home.nix

4. Testing evaluation...
✅ Evaluation OK

=== Phase 1 Complete ===
Phase 2 ready. Continue with /migrate-flake-parts --phase 2
```

### Specific Phase

```bash
$ /migrate-flake-parts --phase 2

=== Phase 2: Core Migration ===

Migrating nixosConfigurations...
✅ framework-16 migrated

Migrating darwinConfigurations...
✅ Zs-MacBook-Pro migrated

Migrating homeConfigurations...
✅ zshen@framework-16 migrated
✅ zshen@Zs-MacBook-Pro migrated

Testing all hosts...
✅ All hosts evaluate OK

=== Phase 2 Complete ===
```

## Rollback

```bash
$ /migrate-flake-parts --rollback

Rolling back changes...

✅ Rolled back to previous state
Run /flake-analyze to verify
```

## Pre-Migration Checklist

Before running migration:

- [ ] Back up current flake.nix
- [ ] Commit any pending changes
- [ ] Test current configuration works
- [ ] Notify users of migration

## Post-Migration

After migration:

1. Test all hosts: `/validate-config --full`
2. Test packages: `nix build .#packages.*`
3. Test dev shell: `nix develop`
4. Update documentation
5. Commit changes

## Benefits of Migration

- **Cleaner code**: Less boilerplate
- **Modular**: NixOS module system for flake
- **Multi-system**: Built-in perSystem
- **Lazy evaluation**: Partitions support
- **Reusable**: Export modules easily
- **Maintainable**: Better organization
