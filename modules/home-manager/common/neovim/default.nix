{ pkgs, lib, config, ... }:

{
  options = {
    neovim.enable =
      lib.mkEnableOption "enable neovim";
  };

  config = lib.mkIf config.neovim.enable {
    programs.neovim =
      let
        toLua = str: "lua << EOF\n${str}\nEOF\n";
        toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
      in
      {
        enable = true;
        package = pkgs.neovim-nightly;

        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        extraPackages = with pkgs; [
          ripgrep
          nodejs_21
          unzip
          cargo
        ];

        plugins = with pkgs.vimPlugins; [
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

          # **telescope.nvim**
          plenary-nvim
          telescope-fzf-native-nvim
          telescope-ui-select-nvim
          nvim-web-devicons

          {
            plugin = telescope-nvim;
            config = toLuaFile ./plugins/telescope.lua;
          }

          # **harpoon**
          {
            plugin = harpoon2;
            config = toLua "require(\"harpoon\"):setup()";
          }

          # **lsp**
          mason-nvim
          mason-lspconfig-nvim
          mason-tool-installer-nvim

          {
            plugin = fidget-nvim;
            config = toLua "require('fidget').setup()";
          }

          {
            plugin = neodev-nvim;
            config = toLua "require('neodev').setup()";
          }

          {
            plugin = nvim-lspconfig;
            config = toLuaFile ./plugins/lsp.lua;
          }

          # **cmp**
          luasnip
          friendly-snippets
          cmp_luasnip
          cmp-nvim-lsp
          cmp-path
          {
            plugin = nvim-cmp;
            config = toLuaFile ./plugins/cmp.lua;
          }

          # **conform**
          {
            plugin = conform-nvim;
            config = toLuaFile ./plugins/conform.lua;
          }

          # **theme**
          tokyonight-nvim
          {
            plugin = catppuccin-nvim;
            config = toLuaFile ./plugins/catppuccin.lua;
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
            plugin = nvim-treesitter.withAllGrammars;
            config = toLuaFile ./plugins/treesitter.lua;
          }

          # **oil.nvim**
          {
            plugin = oil-nvim;
            config = toLua "require('oil').setup()";
          }

          # **noice.nvim**
          # nui-nvim
          # nvim-notify
          # {
          #   plugin = noice-nvim;
          #   config = toLuaFile ./plugins/noice.lua;
          # }

          # **lazygit.nvim**
          # plenary-nvim
          lazygit-nvim
        ];

        extraLuaConfig = ''
          ${builtins.readFile ./config/options.lua}
          ${builtins.readFile ./config/keymaps.lua}
          ${builtins.readFile ./config/autocmds.lua}
          vim.cmd.colorscheme "catppuccin"
        '';
      };

    home.packages = with pkgs; [
      lazygit
    ];
  };

}
