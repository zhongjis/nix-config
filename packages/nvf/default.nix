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

    telescope = {
      enable = true;
      extensions = [
        {
          name = "fzf";
          packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
          setup = {fzf = {fuzzy = true;};};
        }
      ];
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
        formatters = {
          stylua = {
            prepend_args = [
              "--indent-type"
              "Spaces"
              "--indent-width"
              2
              "--column-width"
              85
              "--sort-requires"
            ];
          };
          black = {
            prepend_args = [
              "--line-length"
              85
            ];
          };
          shfmt = {
            args = [
              "-i"
              2
              "-ci"
            ];
          };
        };
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
        format_on_save = {
          _type = "lua-inline";
          expr = ''
            function(bufnr)
                  -- Disable with a global or buffer-local variable
                  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                  end

                  -- Disable "format_on_save lsp_fallback" for languages that don't
                  -- have a well standardized coding style. You can add additional
                  -- languages here or re-enable it for the disabled ones.
                  local disable_filetypes =
                    { c = true, cpp = true, typescript = true, javascript = true, yaml = true }
                  return {
                    timeout_ms = 500,
                    lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                  }
                end
          '';
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
