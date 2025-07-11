{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./autocmds.nix
    ./cmp.nix
    ./formatter.nix
    ./lint.nix
    ./lsp.nix
    ./options.nix
    ./telescope.nix
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
    terminal.toggleterm = {
      enable = true;
      mappings.open = "<leader>tt";

      lazygit = {
        enable = true;
        mappings.open = "<leader>gg";
      };
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
  };
}
