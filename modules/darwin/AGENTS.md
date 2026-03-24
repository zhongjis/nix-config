# DARWIN MODULES

nix-darwin system configuration via auto-discovered features and bundles. This is the Darwin sibling of `modules/nixos/`, but the namespace, bundle contents, and package sources differ.

## AUTO-DISCOVERY

`myLib.extendModules` scans each directory for `.nix` files and wraps them with:
- `myNixDarwin.{name}.enable` for individual features
- `myNixDarwin.bundles.{name}.enable` for bundle files

**No manual registration.** Drop a `.nix` file in `features/` or `bundles/` and it is imported automatically.

## STRUCTURE

```
darwin/
├── default.nix       # Imports features/ + bundles/ via extendModules
├── features/         # Darwin-specific toggles (nh, determinate, macos-system, skhd, sketchybar, yabai)
└── bundles/          # general + work compositions
```

## BUNDLES

| Bundle | Purpose | Notable contents |
|--------|---------|------------------|
| `general` | Base macOS machine setup | `nix-homebrew`, Homebrew taps/casks, `myNixDarwin.macos-system`, `determinate`, `nh` |
| `work` | Extra work machine tools | kubectl/kustomize/terraform/vault, Docker Desktop, IDE casks |

## DARWIN DIFFERENCES

- Namespace is `myNixDarwin.*`, not `myNixOS.*`
- No `services/` layer here — hardware-specialized services stay in `modules/nixos/`
- `users.users.${currentSystemUser}` is the common host pattern on Darwin
- `system.stateVersion` is an integer (`5` here), not the NixOS string form

## PACKAGE BOUNDARY

- Prefer Nix packages for CLI tools in `environment.systemPackages`
- Use `homebrew` / `nix-homebrew` for macOS apps and taps
- `bundles/general.nix` is the local example for mixed Nix + Homebrew setup

## HOST USAGE

```nix
# hosts/mac-m1-max/configuration.nix
imports = [ ../../modules/shared ../../modules/darwin ];

myNixDarwin = {
  bundles.general.enable = true;
  bundles.work.enable = true;
};
```

## COMMANDS

Use the root workflow for deployment:
- `nh darwin switch .`
- `darwin-rebuild switch --flake .#mac-m1-max`
- `nix flake check`

## GOTCHAS

- `features/nh.nix` is intentionally disabled right now; keep the comment unless the upstream nix-darwin issue is resolved
- `bundles/general.nix` sets `nix.enable = false` because Determinate Nix manages the installation
- If a change is Homebrew-only, keep it in the Darwin layer instead of leaking it into shared or NixOS modules
