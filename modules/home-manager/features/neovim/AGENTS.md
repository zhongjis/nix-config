# NEOVIM MODULE

Neovim configuration via NVF (NixVim Framework). Plugin-per-file architecture with Nix+Lua hybrid config.

## STRUCTURE

```
neovim/
├── default.nix           # Entry: programs.nvf.enable, imports ./nvf
├── nvf/
│   ├── default.nix       # Top-level nvf settings, imports config/ + plugins/
│   ├── config/           # Editor configuration
│   │   ├── keymaps.nix   # Global keybindings (vim.keymaps)
│   │   ├── options.nix   # vim.options, vim.globals
│   │   ├── autocmds.nix  # vim.autocmds, vim.augroups
│   │   ├── usrcmds.nix   # Custom user commands
│   │   └── lua/          # Supplementary Lua files (vim.extraLuaFiles)
│   └── plugins/          # One file per plugin
│       ├── cmp.nix       # blink-cmp completion
│       ├── copilot.nix   # AI completion
│       ├── telescope.nix # Fuzzy finder
│       ├── oil.nix       # File explorer
│       ├── lsp/          # LSP configuration
│       │   ├── default.nix  # vim.languages.*.enable
│       │   ├── formatter.nix # conform-nvim
│       │   └── lint.nix     # nvim-lint
│       └── ...           # gitsigns, mini, toggleterm, whichkey, etc.
└── backup/               # Legacy config (unused, reference only)
```

## ADDING A NEW PLUGIN

1. Create `nvf/plugins/{plugin-name}.nix`
2. Add to imports in `nvf/plugins/default.nix`
3. Configure using nvf's `vim.*` namespace:

```nix
{ ... }: {
  # Enable the plugin
  vim.{namespace}.{plugin}.enable = true;

  # Optional: plugin-specific settings
  vim.{namespace}.{plugin}.setupOpts = {
    # Plugin configuration
  };

  # Optional: keybindings
  vim.keymaps = [
    {
      key = "<leader>x";
      mode = "n";
      action = ":SomeCommand<CR>";
      desc = "Description";
    }
  ];

  # Optional: additional packages (external tools)
  vim.extraPackages = with pkgs; [ ripgrep fd ];
}
```

## CONFIG PATTERNS

**Nix-native**: `vim.options`, `vim.globals`, `vim.keymaps`, `vim.autocmds`, `vim.augroups`

**Lua inline** (for complex expressions):
```nix
action = { _type = "lua-inline"; expr = "vim.lsp.buf.definition"; };
```

**Supplementary Lua**: complex logic in `config/lua/*.lua`, loaded via `vim.extraLuaFiles`

## LSP SETUP

```nix
# Enable language support (auto-configures LSP + treesitter)
vim.languages.{lang}.enable = true;
vim.languages.{lang}.lsp.servers = ["server-name"];

# Per-client settings via LspAttach autocmd
vim.luaConfigRC.lsp-settings = "...";
```

**Formatters**: `vim.formatter.conform-nvim` with `formatters_by_ft` mapping
**Completion**: `vim.autocomplete.blink-cmp` with sources, mappings, appearance
