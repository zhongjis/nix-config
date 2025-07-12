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
          "[\"<c-q>\"]" = lib.mkLuaInline "require(\"telescope.actions\").send_to_qflist";
          "[\"<c-a>\"]" = lib.mkLuaInline "require(\"telescope.actions\").add_to_qflist";
          "<ESC>" = lib.mkLuaInline ''require("telescope.actions").close'';
        };
        n = {
          "[\"<c-q>\"]" = lib.mkLuaInline "require(\"telescope.actions\").send_to_qflist";
          "[\"<c-a>\"]" = lib.mkLuaInline "require(\"telescope.actions\").add_to_qflist";
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
}
