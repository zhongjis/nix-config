{
  lib,
  pkgs,
  ...
}: {
  # replacing default hyprland sddm with gdm
  myNixOS.sddm.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce true;

  myNixOS.kde.enable = true;
}
