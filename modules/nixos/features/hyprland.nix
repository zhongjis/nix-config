{
  pkgs,
  inputs,
  lib,
  ...
}: let
  hyprland-pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  services.xserver.enable = true;
  services.displayManager.defaultSession = "hyprland";

  programs.uwsm.enable = false;
  programs.hyprland = {
    enable = true;

    # hyprland git
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    xwayland.enable = true;
    withUWSM = false;
  };

  hardware.graphics = {
    package = hyprland-pkgs-unstable.mesa;
    package32 = hyprland-pkgs-unstable.pkgsi686Linux.mesa;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl # brightness control
    pavucontrol # volume control

    wl-clipboard
    cliphist

    kitty
  ];

  services.gnome.gnome-keyring.enable = lib.mkDefault true; # NOTE: to store password for things like nextcloud-client
  security.pam.services.gnome_keyring = {};
}
