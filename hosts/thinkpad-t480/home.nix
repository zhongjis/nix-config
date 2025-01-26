{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../../modules/shared/home-manager
    ../../modules/nixos/home-manager
  ];

  myHomeManager.bundles.general.enable = true;
  myHomeManager.bundles.linux.enable = true;
  myHomeManager.bundles.hyprland.enable = true;

  programs.git.userName = "zhongjis";
  programs.git.userEmail = "zhongjie.x.shen@gmail.com";

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    google-chrome
  ];
  home.file = {};
}
