{
  pkgs,
  inputs,
  ...
}: {
  wayland.windowManager.hyprland = {
    plugins =
      (with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
        borders-plus-plus
        csgo-vulkan-fix
        hyprbars
        hyprfocus
      ])
      ++ [
        inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}.hy3
        inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
      ];
    settings.plugin.dynamic_cursors = {
      mode = "none";
      shake = {
        threshold = 10.0;
        limit = 4.0;
      };
    };
  };
}
