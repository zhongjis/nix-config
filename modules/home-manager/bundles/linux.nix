{
  lib,
  pkgs,
  ...
}: {
  myHomeManager.xremap.enable = lib.mkDefault true;
  myHomeManager.hyprland.enable = lib.mkDefault true;

  home.packages = with pkgs; [
    bitwarden
  ];
}
