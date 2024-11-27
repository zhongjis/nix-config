{pkgs, ...}: {
  services.xserver.enable = true;

  programs.uwsm.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl # brightness control
    lxqt.lxqt-policykit
    lxqt.pavucontrol-qt # volume control

    wl-clipboard
    cliphist
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
}
