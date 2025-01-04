{
  pkgs,
  inputs,
  ...
}: {
  services.xserver.enable = true;
  services.displayManager.defaultSession = "hyprland-uwsm";

  programs.uwsm.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl # brightness control
    pavucontrol # volume control

    wl-clipboard
    cliphist

    kitty
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # fix Fcitx5 Doesn't Start When Using WM
  # reference: https://nixos.wiki/wiki/Fcitx5
  services.xserver.desktopManager.runXdgAutostartIfNone = true;
}
