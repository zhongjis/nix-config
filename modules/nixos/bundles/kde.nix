{
  lib,
  pkgs,
  ...
}: {
  # replacing default hyprland sddm with gdm
  myNixOS.sddm.enable = lib.mkForce true;
  services.displayManager.gdm.enable = lib.mkForce false;

  myNixOS.kde.enable = true;
}
