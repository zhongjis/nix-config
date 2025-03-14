{pkgs, ...}: let
in {
  imports = [
    ../../modules/shared/home-manager
    ../../modules/nixos/home-manager
  ];

  programs.git.userName = "zhongjis";
  programs.git.userEmail = "zhongjie.x.shen@gmail.com";

  myHomeManager.bundles.general-server.enable = true;

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [];
}
