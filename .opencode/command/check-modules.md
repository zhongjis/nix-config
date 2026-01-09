---
command: /check-modules
description: Validate module imports and structure
syntax: |
  /check-modules [options]
options:
  - --detailed: Show detailed analysis
  - --imports: Check import chains
  - --quality: Check quality standards
  - --fix: Auto-fix common issues
examples:
  - "/check-modules"
  - "/check-modules --detailed"
  - "/check-modules --imports"
  - "/check-modules --fix"
---

# Check Modules Command

Validates module imports, structure, and quality.

## Usage

```bash
/check-modules                 # Basic check
/check-modules --detailed      # Detailed analysis
/check-modules --imports       # Check import chains
/check-modules --quality       # Quality standards check
/check-modules --fix           # Auto-fix issues
```

## Examples

### Basic Check

```bash
$ /check-modules

=== Module Check ===

Total Modules: 45
Validated: 45
Passed: 43
Failed: 2

Modules:
✅ modules/shared/default.nix
✅ modules/shared/home-manager/default.nix
✅ modules/shared/home-manager/bundles/general.nix
...
❌ modules/shared/home-manager/features/neovim/default.nix (300 lines)
❌ modules/nixos/features/hyprland.nix (circular?)

=== Summary ===
2 issues found
Run --detailed for more info
```

### Detailed Check

```bash
$ /check-modules --detailed

=== Detailed Module Analysis ===

## modules/shared/home-manager/features/neovim/default.nix
Lines: 300
Status: ⚠️  Consider splitting

Issues:
- File too long (300 lines)
- Multiple concerns (options, config, plugins, LSP)
- Could be split into:
  - options.nix (50 lines)
  - config.nix (100 lines)
  - plugins.nix (80 lines)
  - lsp.nix (70 lines)

Quality Score: 7/10

## modules/nixos/features/hyprland.nix
Status: ⚠️  Needs attention

Issues:
- Imports hyprland-plugins which imports hyprland
- Potential circular dependency
- Complex configuration

Import Chain:
configuration.nix
└── hyprland.nix
    └── hyprland-plugins
        └── hyprland.nix ⚠️  CIRCULAR

Quality Score: 6/10

## modules/shared/default.nix
Status: ✅ Good

Quality Score: 9/10
```

### Import Chain Check

```bash
$ /check-modules --imports

=== Import Chain Analysis ===

Import Tree: hosts/framework-16/configuration.nix
├── modules/shared/default.nix
│   ├── modules/shared/home-manager/default.nix
│   │   ├── modules/shared/home-manager/bundles/general.nix
│   │   │   └── features/git.nix
│   │   │   └── features/zsh.nix
│   │   └── modules/shared/home-manager/features/alacritty.nix
│   │       └── features/stylix.nix
│   └── modules/nixos/default.nix
│       ├── modules/nixos/features/hyprland.nix
│       │   └── features/hyprland-plugins.nix
│       └── modules/nixos/bundles/general-desktop.nix
│           └── features/hyprland.nix

Circular Dependencies: None found ✅
Missing Imports: None found ✅
Import Depth: 6 levels (acceptable)

=== Import Check Complete ===
```

### Quality Check

```bash
$ /check-modules --quality

=== Module Quality Check ===

## Standards

✅ All modules have maintainers
✅ Boolean options use mkEnableOption
✅ Options have descriptions
✅ Config uses mkIf/mkWhen

## Naming

✅ Consistent naming (myModule, myFeature)
✅ Descriptive option names
✅ Consistent file naming

## Documentation

✅ 40/45 modules have meta.docs
❌ 5 modules missing documentation
   - modules/shared/home-manager/features/ghostty.nix
   - modules/shared/home-manager/features/zen-browser.nix
   - modules/nixos/features/lact.nix
   - modules/nixos/services/amdcpu.nix
   - modules/nixos/services/amdgpu.nix

## Quality Score Distribution
10/10: 15 modules
8-9/10: 20 modules
6-7/10: 8 modules
<6/10: 2 modules

Average: 8.2/10
```

### Auto-Fix

```bash
$ /check-modules --fix

=== Auto-Fixing Issues ===

1. Missing descriptions
   ✅ Added to: ghostty.nix
   ✅ Added to: zen-browser.nix
   ❌ Skipped: lact.nix (complex, manual review needed)

2. Naming consistency
   ✅ Fixed: enabled → enable in 3 modules
   ✅ Fixed: pkg → package in 2 modules

3. Documentation
   ✅ Added basic docs to 2 modules

=== Fix Complete ===
3 issues fixed, 2 require manual review
```

## Common Issues Fixed

| Issue | Auto-Fix | Manual |
|-------|----------|--------|
| Missing descriptions | ✅ | |
| Naming inconsistencies | ✅ | |
| Missing meta.maintainers | ✅ | |
| File too long | ❌ | ✅ |
| Circular dependencies | ❌ | ✅ |
| Complex configuration | ❌ | ✅ |
