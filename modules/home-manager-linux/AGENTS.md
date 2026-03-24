# HOME MANAGER LINUX MODULES

Linux-only Home Manager configuration for the desktop stack. This subtree owns Hyprland, Waybar, swaync, rofi, and related user-session pieces that do not belong in shared Home Manager config.

## AUTO-DISCOVERY

`myLib.extendModules` scans each directory for `.nix` files and wraps them with:
- `myHomeManager.{name}.enable` for features
- `myHomeManager.bundles.{name}.enable` for bundles
- `myHomeManager.services.{name}.enable` for services

## STRUCTURE

```
home-manager-linux/
├── default.nix       # Imports features/ + bundles/ + services/
├── bundles/          # linux + hyprland compositions
├── features/         # hyprland, hyprlock, hyprpaper, hyprsunset, rofi, gtk, distrobox
└── services/         # waybar, swaync, dunst, hypridle
```

## BUNDLES

| Bundle | Purpose | Enables |
|--------|---------|---------|
| `linux` | General Linux desktop defaults | distrobox, noise-cancelling input, MIME app defaults |
| `hyprland` | Wayland desktop stack | hyprland, rofi, hyprlock, hyprpaper, hyprsunset, hypridle, dunst, waybar, gtk |

## HYPRLAND PATTERN

- Host `home.nix` provides monitor/workspace attrsets under `myHomeManager.hyprland.*`
- `features/hyprland/default.nix` converts those attrsets into Hyprland monitor rules and workspace bindings
- Keep `package = null` and `portalPackage = null` so Home Manager uses the NixOS-provided Hyprland packages

## SERVICES PATTERN

- `services/waybar/` is split across `modules.nix`, `config.nix`, and `style.nix`
- `services/waybar/default.nix` exposes a local `restart-waybar` helper and enables Waybar's experimental Meson flag
- `services/swaync/default.nix` sources local `icons/`, `images/`, JSON config, and CSS directly from the subtree

## HOST USAGE

```nix
# hosts/framework-16/home.nix
imports = [ ../../modules/home-manager ../../modules/home-manager-linux ];

myHomeManager.bundles.linux.enable = true;
myHomeManager.bundles.hyprland.enable = true;
```

## COMMANDS

Deployment stays at the repo root:
- `nh os switch .`
- `nix flake check`

Local helper:
- `restart-waybar`

## GOTCHAS

- Hyprland monitor strings use display descriptions, not friendly names; keep host monitor IDs aligned with actual hardware names
- `services.swaync` uses checked-in assets from `icons/` and `images/`; keep those paths relative to the service subtree
- Desktop-session behavior is spread across features and services, so follow the existing split instead of collapsing everything into one file
