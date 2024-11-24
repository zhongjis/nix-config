{
  lib,
  pkgs,
  ...
}: {
  myHomeManagerLinux.xremap.enable = lib.mkDefault true;
  myHomeManagerLinux.hyprland.enable = lib.mkDefault true;
  myHomeManagerLinux.pipewire.enable = lib.mkDefault true;
}
