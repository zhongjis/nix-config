{
  config,
  lib,
  pkgs,
  ...
}: let
in {
  # hyprland
  wayland.windowManager.hyprland = {
    plugins = with pkgs; [
      hyprlandPlugins.hy3
      hyprlandPlugins.csgo-vulkan-fix
    ];
    settings = {
    };
  };
}
