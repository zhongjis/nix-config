---
command: /validate-config
description: Run comprehensive configuration validation
syntax: |
  /validate-config [options]
options:
  - --full: Full validation including builds
  - --host <host>: Validate specific host
  - --modules: Validate module imports only
  - --packages: Validate packages only
examples:
  - "/validate-config"
  - "/validate-config --full"
  - "/validate-config --host framework-16"
  - "/validate-config --packages"
---

# Validate Config Command

Runs comprehensive validation of the entire configuration.

## Usage

```bash
/validate-config              # Standard validation
/validate-config --full       # Full validation with builds
/validate-config --host framework-16  # Specific host
/validate-config --packages   # Packages only
/validate-config --modules    # Modules only
```

## Examples

### Standard Validation

```bash
$ /validate-config

=== Configuration Validation ===

1. Flake Syntax
✅ flake.nix parses correctly

2. Input Check
✅ 20 inputs resolve
✅ No missing inputs

3. Evaluation
✅ flake.nix evaluates
✅ All outputs defined

4. Imports
✅ All modules import correctly
✅ No circular dependencies

5. Home Manager
✅ 3 profiles configure correctly

6. Secrets
✅ secrets/ files valid

=== Validation Complete ===
All checks passed! ✅
```

### Full Validation

```bash
$ /validate-config --full

=== Full Configuration Validation ===

1. Flake Syntax ✅
2. Input Check ✅
3. Evaluation ✅
4. Imports ✅
5. Home Manager ✅
6. Secrets ✅

7. Package Builds
   - neovim: building... ✅
   - helium: building... ✅
   - hello: building... ✅

8. System Builds
   - framework-16: building... ✅
   - Zs-MacBook-Pro: building... ✅

9. Cross-Platform Builds
   - aarch64-linux: ✅
   - aarch64-darwin: ✅

10. Quality Check
    - Module documentation: ✅
    - Naming consistency: ✅
    - Code style: ✅

=== Full Validation Complete ===
All 10 checks passed! ✅
```

### Specific Host

```bash
$ /validate-config --host framework-16

=== Framework-16 Validation ===

1. Configuration
✅ syntax valid
✅ imports resolve

2. Bundles
✅ general-desktop: enabled
✅ developer: enabled
✅ hyprland: enabled
✅ gaming: enabled
✅ 3d-printing: enabled

3. Services
✅ amdcpu: configured
✅ amdgpu: configured
✅ ollama: configured
✅ virt-manager: configured

4. Hardware
✅ framework-16-7040-amd
✅ fw-fanctrl: configured

5. Build Test
✅ system builds successfully

=== Framework-16 Validated ===
Ready for switch.
```

### Packages Only

```bash
$ /validate-config --packages

=== Package Validation ===

1. Package Definitions
✅ neovim: nvf module
✅ helium: packages/helium.nix

2. Build Test
✅ x86_64-linux: neovim ✅
✅ x86_64-linux: helium ✅
✅ aarch64-linux: neovim ✅
✅ aarch64-darwin: neovim ✅

3. Cross-Platform
✅ Platforms correctly defined

=== Package Validation Complete ===
```

## Validation Checklist

| Check | Description | Time |
|-------|-------------|------|
| Syntax | Nix syntax validation | < 1s |
| Inputs | All inputs resolve | < 5s |
| Evaluation | Flake evaluates | < 10s |
| Imports | Module imports | < 5s |
| Packages | Build packages | ~30s |
| Systems | Build system configs | ~60s |
| Full | Everything | ~2min |

## CI Integration

```bash
#!/bin/bash
# .github/workflows/validate.yml

- name: Validate Config
  run: |
    nix run .# -- validate-config --full
    
- name: Check Packages
  run: |
    nix run .# -- validate-config --packages
```
