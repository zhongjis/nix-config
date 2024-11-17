{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    hyprland.enable =
      lib.mkEnableOption "enables hyprland";
  };

  config = lib.mkIf config.hyprland.enable {
    xdg.configFile."hyprland/hyprland.conf".source = ./hyprland.conf;
  };
}
