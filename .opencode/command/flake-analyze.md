---
command: /flake-analyze
description: Analyze the current flake.nix structure and dependencies
syntax: |
  /flake-analyze [options]
options:
  - --detailed: Show detailed analysis
  - --compare: Compare against target structure
  - --json: Output in JSON format
examples:
  - "/flake-analyze"
  - "/flake-analyze --detailed"
  - "/flake-analyze --compare"
---

# Flake Analyze Command

Analyzes the current flake.nix structure, inputs, and outputs.

## Usage

```bash
/flake-analyze                    # Basic analysis
/flake-analyze --detailed        # Detailed with recommendations
/flake-analyze --compare         # Compare current vs target
/flake-analyze --json            # JSON output for scripts
```

## Output

```
# Flake Analysis Report

## Summary
- **Total Inputs**: 20
- **Last Updated**: 2025-01-08
- **Systems**: x86_64-linux, aarch64-linux, aarch64-darwin
- **Evaluation Status**: ✅ Success

## Input Analysis
...

## Output Analysis
...

## Issues Found
...

## Recommendations
...
```

## Examples

### Basic Analysis

```bash
$ /flake-analyze

=== Flake Analysis ===
Inputs: 20 (6 core, 5 desktop, 9 utilities)
Outputs: 3 nixos, 1 darwin, 3 home, 2 packages
Status: ✅ Evaluating correctly

=== Quick Stats ===
Core Inputs: nixpkgs (unstable), home-manager, nix-darwin, sops-nix
Desktop: hyprland, stylix, nvf
Utilities: colmena, xremap, disko

=== Potential Improvements ===
1. Consider adding flake-parts for better modularity
2. Add devShells for development
3. Add formatter and checks
```

### Detailed Analysis

```bash
$ /flake-analyze --detailed

=== Detailed Flake Analysis ===

## Input Breakdown

### Core Infrastructure (6)
- nixpkgs: nixos-unstable ✅
- nixpkgs-stable: nixos-25.11
- home-manager: ✅ follows nixpkgs
- nix-darwin: ✅ follows nixpkgs
- sops-nix: ✅ follows nixpkgs
- disko: ✅ follows nixpkgs

### Desktop Environment (5)
- hyprland: latest
- stylix: latest
- nvf: latest
- neovim-nightly: latest
- minimal-tmux: latest

### Development (4)
- colmena: latest
- xremap-flake: latest
- neovim-nightly-overlay: latest
- nixpkgs-terraform: (unused)

### Hardware (3)
- nixos-hardware: latest
- fw-fanctrl: latest
- zen-browser: latest

### Integration (2)
- flake-parts: NOT PRESENT ⚠️
- determinate: latest

## Output Breakdown

### System Configurations
- nixosConfigurations: 1 (framework-16)
- darwinConfigurations: 1 (Zs-MacBook-Pro)
- homeConfigurations: 3 profiles

### Packages
- neovim: via nvf ✅
- helium: custom package ✅

### Missing Outputs
- devShells: Not defined ⚠️
- checks: Not defined ⚠️
- formatter: Not defined ⚠️

## Quality Score
- Structure: 7/10
- Completeness: 8/10
- Modernization: 5/10 (no flake-parts)

## Recommendations
1. **High Priority**: Add flake-parts input
2. **Medium Priority**: Define devShells
3. **Medium Priority**: Add formatter and checks
4. **Low Priority**: Consolidate similar inputs
```

## Integration with Other Commands

```bash
# After analysis, update flake
/flake-analyze --detailed
/update-flake

# Or migrate to flake-parts
/flake-analyze --compare
/migrate-flake-parts --dry-run
```
