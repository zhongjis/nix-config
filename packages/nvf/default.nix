{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./autocmds.nix
    ./options.nix
    ./lsp.nix
    ./formatter.nix
  ];
  vim = {
    theme.enable = true;
    statusline.lualine.enable = true;

    git.gitsigns = {
      enable = true;
      setupOpts = {
        signs = {
          add = {text = "▎";};
          change = {text = "▎";};
          delete = {text = "";};
          topdelete = {text = "";};
          changedelete = {text = "▎";};
          untracked = {text = "▎";};
        };
      };
    };

    # FIXME: not working
    terminal.toggleterm.lazygit = {
      enable = true;
      mappings.open = "<leader>gg";
    };

    utility.oil-nvim.enable = true;
    binds.whichKey.enable = true;

    notes.todo-comments.enable = true;

    visuals.nvim-web-devicons.enable = true;
    visuals.fidget-nvim.enable = true;

    mini.ai = {
      enable = true;
      setupOpts = {
        n_lines = 500;
      };
    };
    mini.surround.enable = true;

    keymaps = [
      {
        key = "<leader>o";
        mode = "n";
        silent = true;
        action = "<cmd>Oil<cr>";
      }
    ];

    snippets.luasnip.enable = true;

    autocomplete.nvim-cmp = {
      enable = true;
      mappings = {
        next = "<C-n>";
        previous = "<C-p>";
        confirm = "<C-y>";
        complete = "<C-Space>";
      };
      sourcePlugins = ["cmp-path" "cmp-nvim-lsp" "cmp-buffer" pkgs.vimPlugins.cmp_luasnip pkgs.vimPlugins.cmp-cmdline];
    };
  };
}
