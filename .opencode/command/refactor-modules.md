---
command: /refactor-modules
description: Analyze and refactor module organization
syntax: |
  /refactor-modules [options]
options:
  - --analyze: Analyze current organization
  - --duplicates: Find duplicate patterns
  - --consistency: Check naming consistency
  - --recommend: Get refactoring recommendations
  - --apply <type>: Apply specific refactoring
  - --dry-run: Show what would change
examples:
  - "/refactor-modules --analyze"
  - "/refactor-modules --duplicates"
  - "/refactor-modules --recommend"
  - "/refactor-modules --apply consolidation --dry-run"
---

# Refactor Modules Command

Analyzes module organization and performs refactoring.

## Usage

```bash
/refactor-modules --analyze         # Analyze organization
/refactor-modules --duplicates      # Find duplicates
/refactor-modules --consistency     # Check naming
/refactor-modules --recommend       # Get recommendations
/refactor-modules --apply all       # Apply all refactorings
/refactor-modules --dry-run         # Preview changes
```

## Examples

### Analyze

```bash
$ /refactor-modules --analyze

=== Module Organization Analysis ===

## Directory Structure
modules/
├── shared/
│   ├── home-manager/
│   │   ├── bundles/
│   │   │   ├── general.nix ✅
│   │   │   ├── office.nix ✅
│   │   │   └── general-server.nix ✅
│   │   └── features/
│   │       ├── alacritty.nix ✅
│   │       ├── neovim/ ✅
│   │       ├── git.nix ✅
│   │       └── ... (15 more)
│   └── default.nix ✅
├── nixos/
│   ├── features/
│   │   ├── hyprland.nix ✅
│   │   ├── kubernetes.nix ✅
│   │   └── ... (10 more)
│   ├── bundles/
│   │   ├── general-desktop.nix ✅
│   │   ├── gaming.nix ✅
│   │   └── ... (3 more)
│   └── home-manager/
└── darwin/

## Structure Score: 8/10

Strengths:
- Clear separation of concerns
- Consistent naming
- Good bundle organization

Areas for Improvement:
- Some modules could be split
- Inconsistent option structure in a few modules
- lib/default.nix could be enhanced

## Files Needing Attention
- modules/shared/home-manager/features/neovim/default.nix (300 lines, consider splitting)
- modules/nixos/features/hyprland.nix (complex, could simplify)
```

### Find Duplicates

```bash
$ /refactor-modules --duplicates

=== Duplicate Pattern Analysis ===

## Potential Duplicates

1. Import Patterns
   modules/nixos/features/hyprland.nix
   modules/nixos/features/hy3.nix
   → Both import similar Hyprland plugins

2. Option Patterns
   modules/shared/home-manager/features/git.nix
   modules/shared/home-manager/features/lazygit.nix
   → Both have similar `enable` + `settings` structure

3. Configuration Patterns
   Multiple modules have:
   ```
   config = lib.mkIf cfg.enable {
     environment.systemPackages = [...];
   }
   ```
   Consider extracting common pattern

## Recommended Actions
1. Create shared/hyprland-pattern.nix
2. Extract common enable + packages pattern
3. Consolidate similar imports
```

### Get Recommendations

```bash
$ /refactor-modules --recommend

=== Refactoring Recommendations ===

## High Priority

1. Split neovim module (300 lines)
   → Move LSP config to separate file
   → Move plugin config to separate file
   Impact: Easier maintenance

2. Improve lib/default.nix
   → Add flake-parts helpers
   → Add common module patterns
   Impact: Better reusability

## Medium Priority

3. Standardize option naming
   - Use `enable` not `enabled`
   - Use `package` not `pkg`
   Impact: Consistency

4. Extract common patterns
   - `enable + systemPackages` pattern
   - `enable + service` pattern
   Impact: Less duplication

## Low Priority

5. Update documentation
   → Add module docs where missing

6. Clean up unused imports
   → Check for dead code
```

### Apply Refactoring

```bash
$ /refactor-modules --apply consolidation --dry-run

=== Applying consolidation (dry run) ===

Would consolidate:
1. Extract common pattern from:
   - modules/shared/home-manager/features/git.nix
   - modules/shared/home-manager/features/lazygit.nix
   → Create: modules/shared/home-manager/common/enable-packages.nix

2. Merge duplicate imports in:
   - modules/nixos/features/hyprland.nix
   - modules/nixos/features/hy3.nix
   → Create: modules/shared/hyprland/common-plugins.nix

Would NOT modify:
- Host configurations (too risky)
- Secret management (working well)
- Package definitions (different concern)

Run without --dry-run to execute
```

## Refactoring Types

| Type | Description | Risk |
|------|-------------|------|
| `consolidation` | Merge duplicate patterns | Low |
| `naming` | Standardize naming | Medium |
| `split` | Split large modules | Medium |
| `docs` | Add documentation | Low |
| `all` | Apply all refactorings | High |
