{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./config
    ./plugins
  ];
  vim = {
    viAlias = true;
    vimAlias = true;

    theme.enable = true;
    statusline.lualine.enable = true;

    spellcheck = {
      enable = true;
      programmingWordlist.enable = true;
    };

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

    notes.todo-comments.enable = true;

    visuals.nvim-web-devicons.enable = true;
    visuals.fidget-nvim.enable = true;
    visuals.highlight-undo.enable = true;
    visuals.indent-blankline.enable = true;

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
  };
}
