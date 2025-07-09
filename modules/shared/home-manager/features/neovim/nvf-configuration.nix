{
  pkgs,
  lib,
  ...
}: {
  vim = {
    theme.enable = false;
    # and more options as you see fit...

    statusline.lualine.enable = true;
    git.gitsigns.enable = true;
    terminal.toggleterm.lazygit.enable = true;
    utility.oil-nvim.enable = true;
    notes.todo-comments.enable = true;

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
