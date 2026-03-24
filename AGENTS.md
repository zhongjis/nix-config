# PROJECT KNOWLEDGE BASE

NixOS/nix-darwin flake configuration repo. Manages two hosts (NixOS + macOS), Home Manager profiles, custom packages, and AI tool skill infrastructure. Built on flake-parts with auto-discovering module system.

## STRUCTURE

```
nix-config/
├── flake.nix              # Flake entry — inputs + flake-parts imports
├── flake-parts/           # Modular flake config (packages, modules, overlays, systems, templates)
├── hosts/
│   ├── framework-16/      # NixOS x86_64-linux (aiProfile=personal)
│   └── mac-m1-max/        # nix-darwin aarch64-darwin (aiProfile=work)
├── lib/                   # myLib: mkSystem, mkHome, filesIn, dirsIn, extendModules
├── modules/
│   ├── nixos/             # → see modules/nixos/AGENTS.md
│   ├── darwin/            # → see modules/darwin/AGENTS.md
│   ├── home-manager/      # → see modules/home-manager/AGENTS.md
│   ├── home-manager-darwin/  # macOS-only HM (aerospace)
│   ├── home-manager-linux/   # → see modules/home-manager-linux/AGENTS.md
│   └── shared/            # Cross-platform: cachix, packages, stylix
├── overlays/              # modifications (overrides) + stable-packages (nixos-25.11)
├── packages/              # Custom derivations (helium, devtoys, opencode-morph-fast-apply)
├── scripts/               # Input update scripts (homebrew, hyprland, nixos)
├── secrets/               # sops-encrypted YAML
└── templates/             # Dev shells: java8, nodejs22, nextjs
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add NixOS system feature | `modules/nixos/features/` | Auto-discovered, gets `myNixOS.{name}.enable` |
| Add cross-platform HM feature | `modules/home-manager/features/` | See `modules/home-manager/AGENTS.md` |
| Add Linux desktop HM feature | `modules/home-manager-linux/features/` or `modules/home-manager-linux/services/` | See `modules/home-manager-linux/AGENTS.md` |
| Add Darwin system feature | `modules/darwin/features/` | See `modules/darwin/AGENTS.md` |
| Add AI skill | `modules/home-manager/features/ai-tools/common/skills/general/` | See ai-tools/AGENTS.md |
| Add neovim plugin | `modules/home-manager/features/neovim/nvf/plugins/` | See neovim/AGENTS.md |
| Add custom package | `packages/` | See nix-package-creator skill |
| Add dev template | `templates/` + register in `flake-parts/templates.nix` | |
| Add host | `hosts/{name}/` | configuration.nix + home.nix + hardware-configuration.nix |
| Modify overlays | `overlays/default.nix` | `modifications` for overrides, `stable-packages` for stable channel |
| Edit secrets | `nix run nixpkgs#sops -- secrets.yaml` | Age key at `~/.config/sops/age/keys.txt` |
| Update inputs | `nix run github:zhongjis/nix-update-input` | Or `scripts/update-*-inputs.sh` |

## COMMANDS

```bash
# Build & switch
nh darwin switch .                    # macOS
nh os switch .                        # NixOS
darwin-rebuild switch --flake .#mac-m1-max  # macOS (explicit)

# Verify
nix flake check

# Build packages
nix build .#neovim
nix build .#helium

# Dev shells
nix develop .#nodejs22
nix develop .#java8

# Search
nh search <query>
```

## MODULE SYSTEM

All features auto-discovered via `myLib.extendModules`:
- Scans directory for `.nix` files → wraps each with `myOption.{name}.enable` + `mkIf` guard
- **No manual registration** — drop a .nix file, it's discovered
- Option namespaces: `myNixOS.*`, `myNixDarwin.*`, `myHomeManager.*`
- Special args available in all modules: `pkgs`, `lib`, `config`, `inputs`, `currentSystem`, `currentSystemName`, `currentSystemUser`, `isDarwin`, `myLib`

## CONVENTIONS

**Nix style:**
- 2 spaces, never tabs. Always trailing commas in lists/sets
- camelCase for variables/functions/attributes. kebab-case for files/directories
- Relative path imports only (never absolute)
- `let ... in` for local variables. `imports` at top of attribute sets
- Comment language hints: `/* bash */`, `/* json */` for multi-line strings
- Formatter: alejandra

**Shell scripts:** 2 spaces, standard bash, descriptive comments

## ANTI-PATTERNS

- **NEVER** use `git` directly — use Jujutsu (`jj`) for all VCS operations
- **NEVER** use absolute imports in Nix modules
- **NEVER** hardcode system architecture — use `pkgs.stdenv.hostPlatform`
- **NEVER** forget trailing commas in attribute sets/lists
- **NEVER** mix tabs and spaces
- **NEVER** skip `nix flake check` after changes

## VERSION CONTROL (JUJUTSU)

jj auto-tracks changes — no staging step.

```bash
jj status                             # View changes
jj diff --no-pager                    # View diff
jj log --no-pager                     # View history
jj describe -m "type(scope): message" # Set commit message
jj new                                # Start fresh change
jj bookmark set main -r @             # Set bookmark (* = ahead of remote)
jj git push                           # Push to remote
```

Workflow: make changes → `nh darwin/os switch .` → `nix flake check` → `jj describe` → `jj new` → `jj git push`

## SECRETS

sops-nix with age encryption. Key: `~/.config/sops/age/keys.txt`. Edit: `nix run nixpkgs#sops -- secrets.yaml`. Config: `modules/nixos/features/sops.nix`.

## ENVIRONMENT

- Default channel: nixos-unstable. Stable: nixos-25.11 (via `pkgs.stable.*`)
- Flakes enabled. Check `system.stateVersion` in host configs before changing.
- Two profiles: `work` (mac-m1-max) and `personal` (framework-16)

## SUBDIRECTORY KNOWLEDGE

| Path | AGENTS.md | Focus |
|------|-----------|-------|
| `modules/home-manager/features/ai-tools/` | ✅ | Skills, plugins, profiles, MCP |
| `modules/home-manager/` | ✅ | Cross-platform HM features, bundles, services |
| `modules/home-manager-linux/` | ✅ | Linux desktop stack: hyprland, waybar, swaync |
| `modules/darwin/` | ✅ | nix-darwin features, bundles, Homebrew integration |
| `modules/nixos/` | ✅ | Bundles, features, services, option namespaces |
| `modules/home-manager/features/neovim/` | ✅ | NVF framework, plugin patterns |

For AI skill rules, follow `modules/home-manager/features/ai-tools/AGENTS.md`.
