# NIX CONFIG

NixOS/nix-darwin flake repo for two hosts, Home Manager profiles, custom packages, and AI tooling.

## RELATED PRIVATE REPO

This **public** repo consumes a sibling **private** repo as a flake input:

- Path: `~/personal/nix-config-private` — GitHub `zhongjis/nix-config-private` (**private, never public**).
- Holds work-related and private configurations (work modules + sops secrets) that must not be exposed publicly. Same flake-parts/auto-discovery layout as this repo.
- Wired via `inputs.nix-config-private` (`flake.nix`); consumed in host configs, e.g. `hosts/mac-m1-max/home.nix`. Option namespaces there: `zshen-private-flake.*`, `myPrivate.bundles.*`.

When working here, also consider the private repo:

- Changing shared module APIs, option names, or overlay outputs can break the private repo. Check `~/personal/nix-config-private` before such changes.
- `nix flake check` pulls the private input over SSH; failures may originate there.

**PUBLIC/PRIVATE BOUNDARY (BLOCKING):**

- This repo is PUBLIC on GitHub. NEVER copy secrets, decrypted sops content, work-internal names, hostnames, credentials, or any private-repo content into this repo.
- Keep work-related and private logic in `nix-config-private`; reference it via the flake input — do not inline it here.
- Do not add comments/examples/docs here that reveal private or work details.

## COMMANDS

Run from the repo root:

- `nh home switch .` — apply Home Manager / user config changes (`modules/home-manager*`, `custom-home-manager-options`, `programs.pi`)
- `nh os switch .` — apply NixOS system changes
- `nh darwin switch .` — apply nix-darwin system changes
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
- Home Manager-owned changes (including Pi settings under `programs.pi`) require `nh home switch .`, not `nh os switch .` or `nh darwin switch .`.
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

