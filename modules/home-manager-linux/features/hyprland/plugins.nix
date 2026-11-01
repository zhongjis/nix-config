{
  pkgs,
  lib,
  inputs,
  ...
}: {
  wayland.windowManager.hyprland = {
    plugins =
      (with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
        borders-plus-plus
        csgo-vulkan-fix
        hyprfocus
      ])
      ++ [
        inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}.hy3
        # inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
      ];
    # The plugin is disabled above; keep its settings dormant too.
    # Lua rejects options registered only by an unloaded plugin.
    settings = lib.mkIf false {
      config.plugin.dynamic_cursors = {
        mode = "none";
        shake = {
          threshold = 10.0;
          limit = 4.0;
        };
      };
    };
  };
}
