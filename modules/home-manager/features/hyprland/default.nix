{
  lib,
  config,
  ...
}: {
  imports = [
    ./rofi
    ./waybar
    ./swaync
    ./wlogout
    ./hyprland
  ];
  hyprland.enable = lib.mkDefault true;
  rofi.enable = lib.mkDefault true;
  waybar.enable = lib.mkDefault true;
  swaync.enable = lib.mkDefault true;
  wlogout.enable = lib.mkDefault true;
}
