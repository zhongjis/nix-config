---
command: /new-module
description: Create a new Nix module scaffold
syntax: |
  /new-module <name> <category> [options]
options:
  - --options <opt1,opt2>: Add options to module
  - --directory: Create feature directory
  - --force: Overwrite existing module
examples:
  - "/new-module kubernetes nixos/features"
  - "/new-module my-feature shared/home-manager --options enable,setting"
  - "/new-module my-bundle nixos/bundles --directory"
---

# New Module Command

Creates a new Nix module with proper scaffold and structure.

## Usage

```bash
/new-module <name> <category>           # Basic creation
/new-module <name> <category> --options enable,setting  # With options
/new-module <name> <category> --directory  # Feature directory
```

## Categories

| Category | Path | Use Case |
|----------|------|----------|
| `nixos/features` | `modules/nixos/features/<name>/` | System service |
| `nixos/bundles` | `modules/nixos/bundles/<name>/` | Desktop bundle |
| `nixos/home-manager` | `modules/nixos/home-manager/<name>/` | HM integration |
| `darwin/features` | `modules/darwin/features/<name>/` | macOS feature |
| `shared/home-manager` | `modules/shared/home-manager/features/<name>/` | User program |
| `shared` | `modules/shared/<name>.nix` | Cross-platform |

## Examples

### Create NixOS Feature

```bash
$ /new-module kubernetes nixos/features

=== Creating kubernetes module ===
Directory: modules/nixos/features/kubernetes/

Created files:
✅ modules/nixos/features/kubernetes/default.nix

Next steps:
1. Edit the module: modules/nixos/features/kubernetes/default.nix
2. Add to host: hosts/framework-16/configuration.nix
3. Test: nh os switch . --dry-run

Module structure:
- options: myNixOS.features.kubernetes.enable
- config: services.kubernetes
```

### Create with Options

```bash
$ /new-module my-feature nixos/features --options enable,port,package

=== Creating my-feature module ===
Directory: modules/nixos/features/my-feature/

Created files:
✅ modules/nixos/features/my-feature/default.nix

Options added:
- myNixOS.features.my-feature.enable (bool)
- myNixOS.features.my-feature.port (int)
- myNixOS.features.my-feature.package (package)
```

### Create Feature Directory

```bash
$ /new-module my-service nixos/features --directory

=== Creating my-service module (directory structure) ===
Directory: modules/nixos/features/my-service/

Created files:
✅ modules/nixos/features/my-service/default.nix
✅ modules/nixos/features/my-service/options.nix
✅ modules/nixos/features/my-service/config.nix
✅ modules/nixos/features/my-service/README.md

Split structure:
- default.nix: Main module imports
- options.nix: Option definitions
- config.nix: Configuration implementation
- README.md: Documentation
```

### Create Bundle

```bash
$ /new-module gaming nixos/bundles

=== Creating gaming bundle ===
Directory: modules/nixos/bundles/gaming/

Created files:
✅ modules/nixos/bundles/gaming/default.nix

Bundle structure:
- Enables: myNixOS.bundles.gaming.enable
- Includes: nix-gaming features
```

## Generated Module Structure

```nix
# modules/nixos/features/my-feature/default.nix
{ pkgs, lib, config, ... }:

let
  cfg = config.myNixOS.features.my-feature;
in

{
  meta.maintainers = with lib.maintainers; [ "zshen" ];
  
  options = myNixOS.features.my-feature = {
    enable = lib.mkEnableOption "my feature";
  };
  
  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

## Adding to Host

After creating, add to host:

```bash
# Edit host configuration
# hosts/framework-16/configuration.nix

{
  imports = [
    # ... existing imports
    ../../modules/nixos/features/my-feature
  ];
  
  myNixOS = {
    # ... existing config
    features.my-feature.enable = true;
  };
}
```

## Template Options

| Option Type | Syntax | Example |
|-------------|--------|---------|
| Boolean | `enable` | `enable` → `types.bool` |
| String | `setting` | `setting` → `types.str` |
| Integer | `port` | `port` → `types.int` |
| Package | `package` | `package` → `types.package` |
| List | `packages` | `packages` → `types.listOf types.package` |
