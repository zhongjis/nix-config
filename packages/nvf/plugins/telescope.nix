{
  pkgs,
  lib,
  ...
}: let
in {
  vim.extraPackages = with pkgs; [
    fzf
    ripgrep
  ];

  # vim.telescope = {
  #   enable = true;
  #   setupOpts.defaults = {
  #     color_devicons = true;
  #     path_display = ["smart"];
  #     mappings = {
  #       i = {
  #         "[\"<c-q>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").open";
  #         "[\"<c-a>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").add";
  #         "<ESC>" = lib.mkLuaInline ''require("telescope.actions").close'';
  #       };
  #       n = {
  #         "[\"<c-q>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").open";
  #         "[\"<c-a>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").add";
  #       };
  #     };
  #   };
  #   extensions = [
  #     {
  #       name = "fzf";
  #       packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
  #       setup = {fzf = {fuzzy = true;};};
  #     }
  #   ];
  # };

  vim.fzf-lua = {
    enable = true;
    profile = "telescope";
  };

  vim.keymaps = [
    {
      key = "<leader>ff";
      mode = "n";
      silent = true;
      action = "<cmd>FzfLua files<CR>";
    }
    {
      key = "<leader>fr";
      mode = "n";
      silent = true;
      action = "<cmd>FzfLua resume<CR>";
    }
    {
      key = "<leader>fb";
      mode = "n";
      silent = true;
      action = "<cmd>FzfLua buffers<CR>";
    }
    {
      key = "<leader>fg";
      mode = "n";
      silent = true;
      action = "<cmd>FzfLua live_grep<CR>";
    }
    {
      key = "<leader>f/";
      mode = "n";
      silent = true;
      action = "<cmd>FzfLua grep<CR>";
    }
  ];
}
