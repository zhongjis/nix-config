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

  vim.telescope = {
    enable = true;
    setupOpts.defaults = {
      color_devicons = true;
      path_display = ["smart"];
      mappings = {
        i = {
          "[\"<c-q>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").open()";
          "[\"<c-a>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").add()";
          "<ESC>" = lib.mkLuaInline ''require("telescope.actions").close'';
        };
        n = {
          "[\"<c-q>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").open()";
          "[\"<c-a>\"]" = lib.mkLuaInline "require(\"trouble.sources.telescope\").add()";
        };
      };
    };
    extensions = [
      {
        name = "fzf";
        packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
        setup = {fzf = {fuzzy = true;};};
      }
    ];
  };

  # vim.fzf-lua = {
  #   enable = true;
  #   profile = "telescope";
  # };
}
