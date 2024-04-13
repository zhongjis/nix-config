{ lib, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./rofi
  ];

  hyprland.enable = lib.mkDefault true;
  waybar.enable = lib.mkDefault true;
  rofi.enable = lib.mkDefault true;
}
