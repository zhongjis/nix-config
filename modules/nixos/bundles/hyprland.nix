{lib, ...}: {
  myNixOS.hyprland.enable = lib.mkDefault true;
  myNixOS.gdm.enable = lib.mkDefault true;
  myNixOS.sddm.enable = lib.mkDefault false;
}
