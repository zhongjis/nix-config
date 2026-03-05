# NIXOS MODULES

NixOS and nix-darwin system configuration via auto-discovered features, bundles, and services.

## AUTO-DISCOVERY

`myLib.extendModules` scans each directory for `.nix` files and wraps them with:
- `myNixOS.{features|bundles|services}.{name}.enable` option (NixOS)
- `myNixDarwin.{features|bundles}.{name}.enable` option (Darwin)

**No manual registration.** Drop a `.nix` file → it's auto-discovered → enable in host config.

## STRUCTURE

```
nixos/
├── default.nix       # Imports features/, bundles/, services/ via extendModules
├── features/         # 20 individual capabilities
├── bundles/          # 7 feature compositions
└── services/         # 3 hardware-specific (nvidia, amdgpu, amdcpu)

darwin/
├── default.nix
├── features/         # 6 features (yabai, sketchybar, skhd, macos-system, determinate, nh)
└── bundles/          # 2 bundles (general, work)
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

## DARWIN DIFFERENCES

- Namespace: `myNixDarwin.*` (not `myNixOS.*`)
- No services layer (no hardware specialisation)
- Uses Homebrew casks alongside Nix packages
- Features: yabai (tiling WM), sketchybar (bar), skhd (hotkeys), macos-system (defaults), determinate (Nix installer), nh
