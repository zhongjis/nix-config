# NIXOS MODULES

NixOS system configuration via auto-discovered features, bundles, and services. Darwin lives in the sibling `modules/darwin/` subtree.

## AUTO-DISCOVERY

`myLib.extendModules` scans each directory for `.nix` files and wraps them with:
- `myNixOS.{features|bundles|services}.{name}.enable` option

**No manual registration.** Drop a `.nix` file → it's auto-discovered → enable in host config.

## STRUCTURE

```
nixos/
├── default.nix       # Imports features/, bundles/, services/ via extendModules
├── features/         # Individual capabilities
├── bundles/          # Feature compositions
└── services/         # Hardware-specific layers (nvidia, amdgpu, amdcpu)
```

## BUNDLES → FEATURE MAPPINGS

Bundles compose features via `myNixOS.features.{name}.enable = true`:

| Bundle | Enables | Extra |
|--------|---------|-------|
| general-desktop | nh, sops, power-management, stylix, plymouth, flatpak, xremap | firewall, printing, PipeWire, Bluetooth |
| developer | podman (default) | kubernetes, colmena, postgresql, mongodb-compass |
| gaming | lact | Steam, GameMode, Gamescope, Proton, Heroic |
| hyprland | hyprland, gdm | disables sddm |
| kde | kde | disables sddm, enables gdm |
| gnome | gnome | |
| 3d-printing | 3d-printing | |

## FEATURE PATTERNS

Five common patterns in features:

1. **Simple config**: enable NixOS option + set values
2. **Conditional**: inspect `config.myNixOS.*` to react to other features
3. **Hardware specialisation**: GPU/CPU-specific (services/)
4. **External inputs**: use `inputs.*` for flake-provided packages
5. **Bundle composition**: use `mkDefault` for overridable defaults

## HOST USAGE

```nix
# hosts/framework-16/configuration.nix
imports = [ ../../modules/nixos ];     # Auto-discovers everything
myNixOS.bundles.general-desktop.enable = true;
myNixOS.bundles.developer.enable = true;
myNixOS.services.amdgpu.enable = true;
```

## GOTCHAS

- Services are hardware-specialized; do not enable multiple GPU service modules on the same host
- Bundles compose features with `lib.mkDefault`; use host config for final overrides
- Host `system.stateVersion` is effectively immutable after first install
- For nix-darwin rules, use `../darwin/AGENTS.md` instead of adding Darwin detail here
