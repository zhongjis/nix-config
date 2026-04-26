# NIX CONFIG

NixOS/nix-darwin flake repo for two hosts, Home Manager profiles, custom packages, and AI tooling.

## COMMANDS

Run from the repo root:

- `nh darwin switch .`
- `nh os switch .`
- `nix flake check`
- `nix build .#neovim`
- `nix build .#helium`
- `nix develop .#nodejs22`
- `nix develop .#java8`
- `nh search <query>`

## WHERE TO LOOK

| Task                              | Location                                                                         | Notes                                                                                                   |
| --------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Change root flake/module behavior | `flake.nix`, `flake-parts/`, `lib/`                                              | Start with `flake.nix`; module plumbing and auto-discovery helpers live under `flake-parts/` and `lib/` |
| Add NixOS system feature          | `modules/nixos/features/`                                                        | Auto-discovered, gets `myNixOS.{name}.enable`                                                           |
| Add cross-platform HM feature     | `modules/home-manager/features/`                                                 | See `modules/home-manager/AGENTS.md`                                                                    |
| Add Linux desktop HM feature      | `modules/home-manager-linux/features/` or `modules/home-manager-linux/services/` | See `modules/home-manager-linux/AGENTS.md`                                                              |
| Add Darwin system feature         | `modules/darwin/features/`                                                       | See `modules/darwin/AGENTS.md`                                                                          |
| Add AI skill                      | `modules/home-manager/features/ai-tools/common/skills/general/`                  | See `modules/home-manager/features/ai-tools/AGENTS.md`                                                  |
| Add neovim plugin                 | `modules/home-manager/features/neovim/nvf/plugins/`                              | See `modules/home-manager/features/neovim/AGENTS.md`                                                    |
| Add custom package                | `packages/`                                                                      | See nix-package-creator skill                                                                           |
| Add dev template                  | `templates/` + register in `flake-parts/templates.nix`                           |                                                                                                         |
| Add host                          | `hosts/{name}/`                                                                  | `configuration.nix` + `home.nix`; NixOS hosts also carry `hardware-configuration.nix`                   |
| Modify overlays                   | `overlays/default.nix`                                                           | `modifications` for overrides, `stable-packages` for stable channel                                     |
| Edit secrets                      | `secrets/`                                                                       | Use `nix run nixpkgs#sops -- secrets.yaml`                                                              |
| Update inputs                     | `scripts/update-*-inputs.sh` or `nix run github:zhongjis/nix-update-input`       |                                                                                                         |

## GOTCHAS

- Modules are auto-discovered. Add the `.nix` file in the correct subtree and enable the generated option; do not hand-register it.
- Use relative imports in Nix modules, never absolute paths.
- Do not hardcode architecture; use `pkgs.stdenv.hostPlatform`.
- `system.stateVersion` and `home.stateVersion` are host-owned migration boundaries; check the host before changing them.
- Edit secrets with `nix run nixpkgs#sops -- secrets.yaml`; the age key lives at `~/.config/sops/age/keys.txt`.
- Always run `nix flake check` after changes.

## MODULE SYSTEM

- `myLib.extendModules` scans directories for `.nix` files and wraps each with an enable option plus `mkIf`.
- Option namespaces: `myNixOS.*`, `myNixDarwin.*`, `myHomeManager.*`.
- Special args available in modules: `pkgs`, `lib`, `config`, `inputs`, `currentSystem`, `currentSystemName`, `currentSystemUser`, `isDarwin`, `myLib`.

## CONVENTIONS

- Nix uses 2 spaces, never tabs, and keeps trailing commas in lists and attrsets.
- Use camelCase for variables/functions/attrs and kebab-case for files/directories.
- Keep `imports` at the top of attrsets and prefer `let ... in` for local bindings.
- Use comment language hints such as `/* bash */` and `/* json */` for multi-line strings.
- Format Nix with `alejandra`.
- Shell scripts use 2 spaces and descriptive comments.

## SUBDIRECTORY AGENTS

| Path                                      | AGENTS.md | Focus                                              |
| ----------------------------------------- | --------- | -------------------------------------------------- |
| `modules/home-manager/features/ai-tools/` | ✅        | Skills, plugins, profiles, MCP                     |
| `modules/home-manager/`                   | ✅        | Cross-platform HM features, bundles, services      |
| `modules/home-manager-linux/`             | ✅        | Linux desktop stack: hyprland, waybar, swaync      |
| `modules/darwin/`                         | ✅        | nix-darwin features, bundles, Homebrew integration |
| `modules/nixos/`                          | ✅        | Bundles, features, services, option namespaces     |
| `modules/home-manager/features/neovim/`   | ✅        | NVF framework, plugin patterns                     |

For AI skill rules, follow `modules/home-manager/features/ai-tools/AGENTS.md`.

