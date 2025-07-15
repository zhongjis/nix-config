{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./autocmds.nix
  ];
  vim.extraLuaFiles = [
    ./lua/keymaps.lua
    ./lua/options.lua
    ./lua/usrcmds.lua
  ];
}
