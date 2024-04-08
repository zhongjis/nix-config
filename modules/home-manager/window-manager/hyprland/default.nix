{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dunst
    lxqt.lxqt-policykit

    brightnessctl # brightness control
    pavucontrol # volume control GUI

    wl-clipboard
    cliphist
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    extraConfig = ''
      ${builtins.readFile ./hyprland.conf}
    '';
  };
}