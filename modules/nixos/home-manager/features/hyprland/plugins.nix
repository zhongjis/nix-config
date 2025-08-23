{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
in {
  # hyprland
  wayland.windowManager.hyprland = {
    # plugins = with pkgs; [
    plugsin = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
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
