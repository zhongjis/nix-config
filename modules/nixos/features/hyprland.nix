{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  hyprland-pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${system};
  original = inputs.hyprland.packages.${system}.hyprland.override {
    enableXWayland = config.programs.hyprland.xwayland.enable;
  };
  hyprland = (lib.makeOverridable pkgs.symlinkJoin) {
    name = "hyprland-uwsm-${original.version}";
    paths = [original];
    inherit (original) meta version;
    passthru = original.passthru // {inherit (original) man dev;};
    postBuild = ''
      rm "$out/share/wayland-sessions/hyprland-uwsm.desktop"
      substitute ${original}/share/wayland-sessions/hyprland-uwsm.desktop \
        "$out/share/wayland-sessions/hyprland-uwsm.desktop" \
        --replace-fail 'Exec=uwsm start -e -D Hyprland hyprland.desktop' 'Exec=${lib.getExe' config.programs.uwsm.package "uwsm"} start -e -D Hyprland hyprland.desktop' \
        --replace-fail 'TryExec=uwsm' 'TryExec=${lib.getExe' config.programs.uwsm.package "uwsm"}'
    '';
  };
in {
  services.xserver.enable = true;
  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;

    # hyprland git
    package = hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;

    xwayland.enable = true;
    withUWSM = true;
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
