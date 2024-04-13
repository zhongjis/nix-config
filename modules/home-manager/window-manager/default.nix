{ lib, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./rofi
    ./xremap.nix
  ];

  hyprland.enable = lib.mkDefault true;
  waybar.enable = lib.mkDefault true;
  rofi.enable = lib.mkDefault true;
  xremap.enable = lib.mkDefault true;
}
