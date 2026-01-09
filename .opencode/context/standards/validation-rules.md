# Validation Rules

Validation rules for checking Nix modules, packages, and configurations.

## Syntax Validation

### Nix Syntax

```bash
# Check Nix syntax
nix-instantiate --parse file.nix

# Check for syntax errors
nix-instantiate file.nix 2>&1 | head -20

# Check flake syntax
nix-instantiate flake.nix
```

### Common Syntax Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `unexpected '}'` | Extra/missing bracket | Check matching braces |
| `unexpected token` | Typo or missing separator | Add semicolon or comma |
| `infinite recursion` | Circular reference | Break cycle |
| `attribute 'x' missing` | Undefined attribute | Define or import |
| `cannot call a function` | Missing parentheses | Add `()` |

### Check Syntax in Files

```bash
# Check all Nix files
find . -name "*.nix" -exec nix-instantiate --parse {} \; 2>&1 | grep -i error

# Check specific file
nix-instantiate --parse modules/shared/default.nix > /dev/null && echo "OK"
```

## Module Validation

### Import Validation

```bash
# Check imports resolve
nix eval .#nixosConfigurations.framework-16.config.system.build.toplevel 2>&1 | head -20

# Check for missing imports
nix-instantiate ./hosts/framework-16/configuration.nix 2>&1 | grep -i "import"
```

### Option Validation

```bash
# Check option exists
nix eval .#nixosConfigurations.framework-16.config.myNixOS.bundles 2>&1

# List all options
nix-instantiate --eval -E '
  let
    host = (import ./flake.nix {}).nixosConfigurations.framework-16;
  in
    builtins.attrNames host.options.myNixOS
'
```

### Circular Dependency Detection

```bash
# Detect circular imports
nix-instantiate --eval -E '
  let
    mod = import ./modules/nixos/features/hyprland.nix {
      pkgs = import <nixpkgs> {};
      lib = (import <nixpkgs> {}).lib;
      config = {};
      options = {};
    };
  in
    "Checking for circular dependencies..."
' 2>&1 | grep -i circular || echo "No circular dependencies found"
```

## Configuration Validation

### NixOS Configuration

```bash
# Dry-run switch
nh os switch . --dry-run

# Check configuration
nix-instantiate -E '
  let
    host = (import ./flake.nix {}).nixosConfigurations.framework-16;
  in
    host.config.system.stateVersion
'

# Validate all imports
nix eval .#nixosConfigurations --no-link
```

### Home Manager Configuration

```bash
# Validate HM configuration
home-manager dry-activate --flake .#zshen@framework-16 2>&1 | head -20

# Check configuration
nix eval .#homeConfigurations."zshen@framework-16".activationPackage
```

### Flake Validation

```bash
# Full flake evaluation
nix eval .# --apply builtins.attrNames

# Check outputs
nix flake show

# Check all systems
nix eval .#packages.x86_64-linux --no-link
nix eval .#packages.aarch64-linux --no-link
nix eval .#packages.aarch64-darwin --no-link
```

## Package Validation

### Build Validation

```bash
# Test package builds
nix build .#packages.x86_64-linux.hello

# Test all packages
nix build .#packages.*

# Test specific package
nix build .#helium
```

### Dependency Validation

```bash
# Check dependencies
nix-tree ./result

# Show derivation
nix show-derivation ./result

# Check inputs
nix-instantiate --parse ./packages/helium.nix
```

### Cross-Platform Validation

```bash
# Test on other systems
nix build .#packages.aarch64-linux.hello --system aarch64-linux

# Check platform support
nix-instantiate --eval -E '
  let
    pkg = import ./packages/helium.nix {
      pkgs = import <nixpkgs> { system = "x86_64-linux"; };
    };
  in
    pkg.meta.platforms or []
'
```

## Import Chain Validation

### Check Import Chain

```bash
# Show import chain
nix-instantiate --eval -E '
  let
    flake = import ./flake.nix {};
    host = flake.nixosConfigurations.framework-16;
  in
    builtins.concatStringsSep "\n" (host.config._module.args.currentSystemName or "unknown")
'
```

### Validate All Imports

```bash
# Check all imports exist
for f in $(find . -name "*.nix" -type f); do
  echo "Checking $f..."
  nix-instantiate --parse "$f" > /dev/null 2>&1 || echo "ERROR in $f"
done
```

## Secret Validation

### SOPS Validation

```bash
# Validate YAML syntax
nix run nixpkgs#sops -- --validate secrets.yaml

# Check encryption
nix run nixpkgs#sops -d secrets.yaml | head -10

# Check secrets configuration
nix eval .#nixosConfigurations.framework-16.config.sops.secrets
```

### Secret File Validation

```bash
# Verify all secrets are encrypted
grep -r "^secrets:" secrets/ | while read file; do
  nix run nixpkgs#sops -- --validate "$file" || echo "Invalid: $file"
done
```

## Host Validation

### Framework-16

```bash
# Validate framework-16
nix eval .#nixosConfigurations.framework-16.config.myNixOS.bundles --no-link

# Check hardware
nix eval .#nixosConfigurations.framework-16.config.hardware.cpu --no-link

# Dry-run switch
nh os switch . --dry-run
```

### MacBook Pro

```bash
# Validate macOS
nix eval .#darwinConfigurations.Zs-MacBook-Pro.config --no-link

# Check services
nix eval .#darwinConfigurations.Zs-MacBook-Pro.config.services.yabai.enable --no-link
```

## Quality Validation

### Module Quality

```bash
# Check for missing descriptions
/check-modules --quality

# Check naming consistency
/check-modules --naming
```

### Documentation Check

```bash
# Check module documentation
find modules -name "*.nix" -exec grep -L "meta.doc" {} \;

# Check README updates
git diff --name-only README.md
```

## Automated Validation Script

```bash
#!/usr/bin/env bash
# scripts/validate.sh

set -e

echo "=== Nix Flake Validation ==="

# Check syntax
echo "1. Checking syntax..."
nix-instantiate flake.nix > /dev/null && echo "   ✅ Syntax OK"

# Check packages
echo "2. Checking packages..."
nix build .#packages.x86_64-linux.hello --no-link && echo "   ✅ Packages OK"

# Check NixOS
echo "3. Checking NixOS..."
nix eval .#nixosConfigurations.framework-16 --no-link && echo "   ✅ NixOS OK"

# Check Darwin
echo "4. Checking Darwin..."
nix eval .#darwinConfigurations.Zs-MacBook-Pro --no-link && echo "   ✅ Darwin OK"

# Check Home Manager
echo "5. Checking Home Manager..."
nix eval .#homeConfigurations --no-link && echo "   ✅ Home Manager OK"

# Check imports
echo "6. Checking imports..."
nix eval .#nixosConfigurations.framework-16.config.system.build.toplevel > /dev/null && echo "   ✅ Imports OK"

# Check secrets
echo "7. Checking secrets..."
nix run nixpkgs#sops -- --validate secrets/*.yaml > /dev/null && echo "   ✅ Secrets OK"

echo ""
echo "=== All validations passed! ==="
```

## Validation Before Switch

### Pre-Switch Checklist

```bash
#!/usr/bin/env bash
# scripts/pre-switch-check.sh

echo "Pre-switch validation..."

# 1. Check syntax
nix-instantiate flake.nix || { echo "❌ Syntax error"; exit 1; }

# 2. Dry run
nh os switch . --dry-run || { echo "❌ Build error"; exit 1; }

# 3. Check imports
nix eval .#nixosConfigurations.framework-16.config.system.build.toplevel || { echo "❌ Import error"; exit 1; }

# 4. Check packages
nix build .#packages.x86_64-linux.hello --no-link || { echo "❌ Package error"; exit 1; }

echo "✅ All pre-switch checks passed"
```

## Error Message Interpretation

### Common Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| `attribute 'foo' missing` | Undefined attribute | Check spelling, imports |
| `infinite recursion` | Circular reference | Break cycle in imports |
| `cannot call a function` | Function not called | Add `()` |
| `value is null` | Null where value expected | Check option type |
| `hash mismatch` | Wrong SHA256 | Fetch and update hash |
| `permission denied` | File permission issue | `chmod` the file |
| `builder for x would have a result` | Output exists | Delete or use `--impure` |
