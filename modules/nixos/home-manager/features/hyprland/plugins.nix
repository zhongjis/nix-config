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
      hyprlandPlugins.hypr-dynamic-cursors
    ];
    settings = {
      "plugin:dynamic-cursors" = {
        mode = "none";
        shake = {
          threadhold = 10.0;
          limit = 4.0;
        };
      };
    };
  };
}
