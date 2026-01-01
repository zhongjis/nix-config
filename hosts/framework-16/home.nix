{pkgs, ...}: let
  internalMonitor = "desc:BOE 0x0BC9";
  lgUntraWideMonitor = "desc:ASUSTek COMPUTER INC PG27UCDM T1LMAS019666";
  dellMonitor = "desc:Dell Inc. DELL P2419H 78NFR63";
in {
  imports = [
    ../../modules/shared/home-manager
    ../../modules/nixos/home-manager
  ];
  myHomeManager.bundles.general.enable = true;
  myHomeManager.hyprland.monitors = {
    "desc:BOE 0x0BC9" = {
      width = 2560;
      height = 1600;
      refreshRate = 165.;
      x = 0;
      y = 0;
      scale = 1.0;
      # scale = 1.;
    };
    "desc:ASUSTek COMPUTER INC PG27UCDM T1LMAS019666" = {
      width = 3840;
      height = 2160;
      refreshRate = 240.0;
      scale = 1.5;
      # x = 2560
      x = 2560;
      y = 0;
    };
    "desc:Dell Inc. DELL P2419H 78NFR63" = {
      width = 1920;
      height = 1080;
      refreshRate = 60.;
      # x = 6000;
      x = 5488;
      y = 0;
      rotate = 1;
    };
  };
  myHomeManager.hyprland.workspaces = {
    "name:spotify" = {
      monitorId = internalMonitor;
      autostart = with pkgs; [];
    };
    "name:gaming" = {
      monitorId = lgUntraWideMonitor;
      autostart = with pkgs; [];
    };
    "name:zen" = {
      monitorId = lgUntraWideMonitor;
      autostart = with pkgs; [];
    };
  };

  myHomeManager.bundles.linux.enable = true;
  myHomeManager.bundles.hyprland.enable = true;
  myHomeManager.bundles.office.enable = true;

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [];
}
