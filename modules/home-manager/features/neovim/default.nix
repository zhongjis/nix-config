{
  pkgs,
  isDarwin,
  currentSystemName,
  ...
}: let
  toLua = str: "lua << EOF\n${str}\nEOF\n";
  toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";

  systemOption =
    if isDarwin
    then ''
      nix_darwin = {
        expr = '(builtins.getFlake "~/personal/nix-config").darwinConfigurations.${currentSystemName}.options',
      },
    ''
    else ''
      nixos = {
        expr = '(builtins.getFlake "~/personal/nix-config").nixosConfigurations.${currentSystemName}.options',
      },
    '';

  nixdOptionsLua =
    systemOption
    + ''
      home_manager = {
        expr = '(builtins.getFlake "~/personal/nix-config").homeConfigurations.${currentSystemName}.options',
      },
    '';
in {
  programs.neovim = {
    enable = true;
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    package = pkgs.stable.neovim-unwrapped;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;

    withNodeJs = true;

    extraLuaPackages = luaPkgs:
      with luaPkgs; [
        jsregexp # for luasnip
      ];
    extraPackages = with pkgs; [
      # Mason lspconfig build dependencies
      cargo

      # telecope grep
      ripgrep

      # LSP
      nixd

      # Formatters
      stylua
      nixpkgs-fmt
      alejandra
      shfmt
      prettierd
      black
    ];

    plugins = with pkgs.stable.vimPlugins; [
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
      friendly-snippets
      luasnip

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
          p.kdl
          p.toml
          p.hyprlang
          p.css
          p.bash
          p.groovy
          p.xml
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

      # **undotree**
      undotree

      # **zen-mode-nvim
      zen-mode-nvim

      # **copilot.vim**
      copilot-vim
    ];

    extraLuaConfig =
      /*
      lua
      */
      ''
        ${builtins.readFile ./config/options.lua}
        ${builtins.readFile ./config/keymaps.lua}
        ${builtins.readFile ./config/autocmds.lua}
        vim.cmd.colorscheme "catppuccin-mocha"

        -- nixd
        require("lspconfig").nixd.setup({
          cmd = { "nixd" },
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import <nixpkgs> { }",
              },
              options = { ${nixdOptionsLua} },
            },
          },
        })

      '';
  };

  home.packages = with pkgs; [
    lazygit
  ];
}
