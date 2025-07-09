{
  config,
  pkgs,
  ...
}: let
in {
  vim = {
    theme = {
      enable = true;
      name = "base16";
      style = "dark";
      # base16-colors = colors;
      # transparent = false;
    };

    statusline.lualine = {
      enable = true;
      theme = "base16";
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
    terminal.toggleterm.lazygit.enable = true;
    utility.oil-nvim.enable = true;
    notes.todo-comments.enable = true;
    visuals.nvim-web-devicons.enable = true;

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

    telescope = {
      enable = true;
      extensions = [
        {
          name = "fzf";
          packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
          setup = {fzf = {fuzzy = true;};};
        }
      ];
      mappings = {
        liveGrep = "<leader>sg";
        findFiles = "<leader>sf";
      };
    };

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

    lsp.enable = true;

    languages = {
      enableTreesitter = true;

      lua = {
        enable = true;
        lsp.lazydev.enable = true;
      };
      nix.enable = true;
      ts.enable = true;
      java.enable = true;
      terraform.enable = true;
      yaml.enable = true;
      python.enable = true;
    };

    formatter.conform-nvim = {
      enable = true;
      setupOpts.formatters_by_ft = {
        lua = ["stylua"];
        nix = ["alejandra"];
        sh = ["shfmt"];
        javascript = ["prettierd"];
        typescript = ["prettierd"];
        yaml = ["prettierd"];
        markdown = ["prettierd"];
        python = ["black"];
        css = ["prettierd"];
        terraform = ["terraform_fmt"];
        java = ["google-java-format"];
        xml = ["xmlstarlet"];
      };
    };
  };
}
