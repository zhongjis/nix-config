# HOME MANAGER MODULES

Cross-platform Home Manager configuration via auto-discovered features, bundles, and services. Use this subtree for shared user-level config before reaching for the Linux-only or Darwin-only Home Manager trees.

## AUTO-DISCOVERY

`myLib.extendModules` scans each directory for `.nix` files and wraps them with:
- `myHomeManager.{name}.enable` for features
- `myHomeManager.bundles.{name}.enable` for bundles
- `myHomeManager.services.{name}.enable` for services

**No manual registration.** New files in `features/`, `bundles/`, or `services/` are imported automatically.

## STRUCTURE

```
home-manager/
├── default.nix       # Imports features/ + bundles/ + services/ via extendModules
├── bundles/          # Shared compositions such as general
├── features/         # Cross-platform user features
│   ├── ai-tools/     # → see features/ai-tools/AGENTS.md
│   ├── neovim/       # → see features/neovim/AGENTS.md
│   └── ...           # git, ssh, zsh, stylix, terminals, browsers
└── services/         # Shared user services (tmux, etc.)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add shared HM feature | `features/` | Exposes `myHomeManager.{name}.enable` |
| Add shared HM bundle | `bundles/` | Exposes `myHomeManager.bundles.{name}.enable` |
| Add shared HM service | `services/` | Exposes `myHomeManager.services.{name}.enable` |
| Edit AI tooling | `features/ai-tools/` | Has its own AGENTS.md |
| Edit Neovim | `features/neovim/` | Has its own AGENTS.md |

## BUNDLE PATTERN

- Bundles compose features with `lib.mkDefault` so hosts can override them
- `bundles/general.nix` is the reference composition for shared CLI, editor, AI, and shell defaults
- Keep features independent; let bundles wire them together

## HOST USAGE

```nix
# hosts/*/home.nix
imports = [ ../../modules/home-manager ];

myHomeManager.bundles.general.enable = true;
myHomeManager.aiProfile = "work"; # or "personal" when ai-tools is enabled
```

## GOTCHAS

- `home.stateVersion` is host-owned and effectively immutable after first setup
- `myHomeManager.aiProfile` must be set in host `home.nix` when `ai-tools` is enabled, or evaluation fails on the module assertion
- Put platform-specific HM config in `modules/home-manager-linux/` or `modules/home-manager-darwin/`, not here

## COMMANDS

Deployment stays at the repo root:
- `nh darwin switch .`
- `nh os switch .`
- `nix flake check`
