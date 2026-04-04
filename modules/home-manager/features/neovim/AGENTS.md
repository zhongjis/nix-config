# NEOVIM MODULE

Neovim configuration via NVF. Run commands from the repo root.

## COMMANDS

- `nh darwin switch .`
- `nh os switch .`
- `nix flake check`

## WHERE TO EDIT

- `default.nix` enables `programs.nvf` and imports `./nvf`
- `nvf/config/` holds editor-wide behavior: options, keymaps, autocmds, user commands, and shared Lua
- `nvf/plugins/` keeps the plugin-per-file modules
- `nvf/plugins/lsp/formatter.nix` is the first place to check for formatter wiring; per-language overrides may also live in `nvf/plugins/lsp/default.nix`
- `backup/` is reference-only; runtime does not load it

## GOTCHAS

- A new plugin file does nothing until you import it in `nvf/plugins/default.nix`
- Prefer `vim.*` options first; use `_type = "lua-inline"` only when NVF cannot express the behavior cleanly
- Multi-step Lua belongs in `nvf/config/lua/*.lua` via `vim.extraLuaFiles`, not in large inline strings
- Do not edit `backup/` expecting runtime effect
- Keep language-tooling changes under `nvf/plugins/lsp/` when that boundary already fits the change
- Formatter fixes can span `nvf/plugins/lsp/formatter.nix` and per-language overrides in `nvf/plugins/lsp/default.nix`; check both before changing active tooling

## CONVENTIONS

- Keep the plugin-per-file pattern in `nvf/plugins/`
- Keep editor-wide behavior in `nvf/config/`, not scattered across plugin files
- Add external CLI dependencies in the module that needs them so the tool requirement stays local