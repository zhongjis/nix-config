{
  pkgs,
  lib,
  config,
  ...
}: let
  reloadNvim = ''
    XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
    for server in $XDG_RUNTIME_DIR/nvim.*; do
      nvim --server $server --remote-send '<Esc>:source $MYVIMRC<CR>' &
    done
  '';

  toLua = str: "lua << EOF\n${str}\nEOF\n";
  toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
in {
  options = {
    neovim.enable =
      lib.mkEnableOption "enable neovim";
  };

  config = lib.mkIf config.neovim.enable {
    programs.neovim = {
      enable = true;
      # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      package = pkgs.unstable.neovim-unwrapped;

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      withNodeJs = true;

      extraPackages = with pkgs; [
        cargo # Depdency for Mason Install packages

        ripgrep

        # Formatters
        stylua
        nixpkgs-fmt
        alejandra
        shfmt
        prettierd
      ];

      extraLuaPackages = luaPkgs:
        with luaPkgs; [
          jsregexp
        ];

      plugins = with pkgs.vimPlugins; [
        # **telescope.nvim**
        nvim-web-devicons
        plenary-nvim
        telescope-fzf-native-nvim
        {
          plugin = telescope-nvim;
          config = toLuaFile ./plugins/telescope.lua;
        }

        # **lsp**
        neodev-nvim
        fidget-nvim

        mason-nvim
        mason-lspconfig-nvim
        {
          plugin = nvim-lspconfig;
          config = toLuaFile ./plugins/lsp.lua;
        }

        # **cmp**
        lspkind-nvim
        {
          plugin = nvim-cmp;
          config = toLuaFile ./plugins/cmp.lua;
        }
        cmp-buffer
        cmp-path
        cmp_luasnip
        cmp-cmdline
        cmp-nvim-lsp
        cmp-nvim-lua

        # **snippets**
        luasnip
        friendly-snippets

        # **trouble.nvim**
        {
          plugin = trouble-nvim;
          config = toLuaFile ./plugins/trouble.lua;
        }

        # **sleuth**
        vim-sleuth

        # **coment.nvim**
        {
          plugin = comment-nvim;
          config = toLua "require(\"Comment\").setup()";
        }

        # **gitsigns.nvim**
        {
          plugin = gitsigns-nvim;
          config = toLuaFile ./plugins/gitsigns.lua;
        }

        # **which-key**
        {
          plugin = which-key-nvim;
          config = toLuaFile ./plugins/which-key.lua;
        }

        # **harpoon**
        {
          plugin = harpoon2;
          config = toLua "require(\"harpoon\"):setup()";
        }

        # **conform**
        {
          plugin = conform-nvim;
          config = toLuaFile ./plugins/conform.lua;
        }

        # **theme**
        # {
        #   plugin = solarized-osaka-nvim;
        #   config = toLuaFile ./plugins/themes/solarized-osaka.lua;
        # }
        # tokyonight-nvim
        {
          plugin = catppuccin-nvim;
          config = toLuaFile ./plugins/themes/catppuccin.lua;
        }

        # **lualine.nvim**
        {
          plugin = lualine-nvim;
          config = toLuaFile ./plugins/lualine.lua;
        }

        # **todo-comments.nvim**
        # plenary-nvim
        {
          plugin = todo-comments-nvim;
          config = toLua "require('todo-comments').setup{ signs = false }";
        }

        # **mini.nvim**
        {
          plugin = mini-nvim;
          config = toLuaFile ./plugins/mini.lua;
        }

        # **nvim-treesitter**
        {
          plugin = nvim-treesitter.withPlugins (p: [
            p.c
            p.java
            p.nix
            p.python
            p.yaml
            p.json
            p.javascript
            p.typescript
            p.markdown
            p.markdown_inline
            p.hcl
            p.terraform
          ]);
          config = toLuaFile ./plugins/treesitter.lua;
        }

        # **oil.nvim**
        {
          plugin = oil-nvim;
          config = toLua "require('oil').setup()";
        }

        # **noice.nvim**
        # nui-nvim
        # {
        #   plugin = nvim-notify;
        #   config = toLuaFile ./plugins/notify.lua;
        # }
        # {
        #   plugin = noice-nvim;
        #   config = toLuaFile ./plugins/noice.lua;
        # }

        # **lazygit.nvim**
        # plenary-nvim
        lazygit-nvim

        undotree

        zen-mode-nvim
      ];

      extraLuaConfig = ''
        ${builtins.readFile ./config/options.lua}
        ${builtins.readFile ./config/keymaps.lua}
        ${builtins.readFile ./config/autocmds.lua}
        vim.cmd.colorscheme "catppuccin-mocha"
      '';
    };

    xdg.configFile."nvim/init.lua".onChange = reloadNvim;

    home.packages = with pkgs; [
      lazygit
    ];

    home.sessionVariables.EDITOR = "nvim";
  };
}
