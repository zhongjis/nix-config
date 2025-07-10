{
  config,
  pkgs,
  ...
}: let
in {
  vim = {
    theme.enable = true;
    statusline.lualine.enable = true;

    lsp.enable = true;

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

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

    terminal.toggleterm.lazygit = {
      enable = true;
      mappings.open = "<leader>gg";
    };

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

    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
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

    extraPackages = with pkgs; [
      fzf
      ripgrep
      stylua
      nixpkgs-fmt
      alejandra
      shfmt
      prettierd
      black
      google-java-format
      xmlstarlet
    ];
  };
}
