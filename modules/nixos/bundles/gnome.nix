{lib, ...}: {
  # replacing default hyprland sddm with gdm
  myNixOS.sddm.enable = lib.mkForce false;
  services.xserver.displayManager.gdm.enable = true;

  # enable gnome
  services.xserver.desktopManager.gnome.enable = true;
}
