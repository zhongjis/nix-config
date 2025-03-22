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
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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
}
