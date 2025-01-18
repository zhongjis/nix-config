{
  pkgs,
  isDarwin,
  currentSystemName,
  config,
  inputs,
  ...
}: let
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
    ];

    plugins = with pkgs.stable.vimPlugins; [
      # **telescope.nvim**
      nvim-web-devicons
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-nvim

      # **lsp**
      lazydev-nvim
      luvit-meta
      fidget-nvim

      # mason-nvim
      # mason-lspconfig-nvim
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

      # **theme**
      catppuccin-nvim

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
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./init.lua}

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

  xdg.configFile."nvim/lua" = {
    recursive = true;
    source = ./lua;
  };

  home.packages = with pkgs; [
    lazygit
  ];
}
