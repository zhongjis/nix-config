{
  inputs,
  pkgs,
  ...
}: {
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "mocha";
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      binPath = "/run/current-system/sw/bin/Hyprland";
      comment = "Hyprland session managed by uwsm";
      prettyName = "Hyprland";
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    dunst
    lxqt.lxqt-policykit

    brightnessctl # brightness control
    pavucontrol # volume control GUI

    wl-clipboard
    cliphist

    dolphin
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
  };

  # NOTE: if game has issue
  # hardware.opengl = {
  #   package = pkgs.unstable.mesa.drivers;
  #   # if you also want 32-bit support (e.g for Steam)
  #   driSupport32Bit = true;
  #   package32 = pkgs.unstable.pkgsi686Linux.mesa.drivers;
  # };

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };
}
