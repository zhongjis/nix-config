{lib, ...}: {
  myNixOS.hyprland.enable = lib.mkDefault true;
  myNixOS.gdm.enable = lib.mkDefault true;
  myNixOS.gdm.sddm = lib.mkDefault false;
}
