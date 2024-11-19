{
  lib,
  config,
  ...
}: {
  imports = [
    ./rofi
    ./waybar
    ./hyprland
  ];
  options = {
    zshen-hyprland.enable =
      lib.mkEnableOption "enable my personal Hyprland config";
  };

  config = lib.mkIf config.zshen-hyprland.enable {
    rofi.enable = lib.mkDefault true;
    hyprland.enable = lib.mkDefault true;
    waybar.enable = lib.mkDefault true;
  };
}
