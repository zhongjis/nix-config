{
  pkgs,
  config,
  inputs,
  ...
}: let
in {
  home.sessionVariables = {
    JDTLS_PATH = "${pkgs.jdt-language-server}/bin/jdtls";
  };

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    # package = pkgs.stable.neovim-unwrapped;

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
      # treesitter dep
      gcc

      # telecope grep
      ripgrep

      # LSP for nvim-lspconfig
      lua-language-server
      nixd
      vscode-langservers-extracted
      yaml-language-server
      terraform-ls
      typescript-language-server
      jdt-language-server
      pyright
      bash-language-server
      vscode-langservers-extracted

      # Linters
      tflint
      tfsec
      markdownlint-cli

      # Formatters
      stylua
      nixpkgs-fmt
      alejandra
      shfmt
      prettierd
      black
      google-java-format
      xmlstarlet
    ];

    plugins = with pkgs.stable.vimPlugins; [
      # **telescope.nvim**
      nvim-web-devicons
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-nvim

      # **lsp**
      lazydev-nvim
      fidget-nvim

      nvim-lspconfig

      nvim-lint

      # **cmp**
      lspkind-nvim
      nvim-cmp
      cmp-buffer
      cmp-path
      cmp_luasnip
      cmp-cmdline
      cmp-nvim-lsp
      cmp-nvim-lua

      nvim-jdtls

      fastaction-nvim

      # **snippets**
      friendly-snippets
      luasnip

      # **trouble.nvim**
      trouble-nvim

      # **sleuth**
      vim-sleuth

      # **coment.nvim**
      comment-nvim

      # **gitsigns.nvim**
      gitsigns-nvim

      # **harpoon**
      harpoon2

      # **conform**
      conform-nvim

      # **lualine.nvim**
      lualine-nvim

      # **todo-comments.nvim**
      # plenary-nvim
      todo-comments-nvim

      # **mini.nvim**
      mini-nvim

      # **nvim-treesitter**
      nvim-treesitter

      # **oil.nvim**
      oil-nvim

      # **lazygit.nvim**
      # plenary-nvim
      lazygit-nvim

      # **git-blame.nvim**
      git-blame-nvim

      # **undotree**
      undotree

      # **zen-mode-nvim
      zen-mode-nvim

      # **copilot.vim**
      copilot-vim

      # **lazy.nvim**
      lazy-nvim

      # **which-key**
      which-key-nvim

      # **indent-blankline-nvim**
      indent-blankline-nvim
    ];

    extraLuaConfig = ''
      require("config.options")
      require("config.keymaps")
      require("config.autocmds")

      require("lazy").setup({
        performance = {
          reset_packpath = false,
          rtp = {
            reset = false,
          },
        },
        dev = {
          path = "${pkgs.vimUtils.packDir config.programs.neovim.finalPackage.passthru.packpathDirs}/pack/myNeovimPackages/start",
          patterns = { "" },
        },
        install = {
          -- Safeguard in case we forget to install a plugin with Nix
          missing = false,
        },
        spec = {
          { import = "plugins" },
        },
      })
    '';
  };

  xdg.configFile."nvim/lua" = {
    recursive = true;
    source = ./lua;
  };
  xdg.configFile."nvim/ftplugin" = {
    recursive = true;
    source = ./ftplugin;
  };

  home.packages = with pkgs; [
    lazygit
  ];
}
