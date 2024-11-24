{
  lib,
  pkgs,
  ...
}: {
  myHomeManagerLinux.xremap.enable = lib.mkDefault true;
  myHomeManagerLinux.hyprland.enable = lib.mkDefault true;

  home.packages = with pkgs; [
    bitwarden
  ];
}
