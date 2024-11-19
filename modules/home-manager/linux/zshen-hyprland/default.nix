{
  lib,
  config,
  ...
}: {
  imports = [
    ./rofi
    ./waybar
    ./swaync
    ./hyprland
  ];
  options = {
    zshen-hyprland.enable =
      lib.mkEnableOption "enable my personal Hyprland config";
  };

  config = lib.mkIf config.zshen-hyprland.enable {
    hyprland.enable = lib.mkDefault true;
    rofi.enable = lib.mkDefault true;
    waybar.enable = lib.mkDefault true;
    swaync.enable = lib.mkDefault true;
  };
}
