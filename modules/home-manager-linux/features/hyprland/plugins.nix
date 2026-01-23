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
    plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
      [
        # csgo-vulkan-fix
      ]
      ++ [
        # inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}.hy3
        # inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
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
