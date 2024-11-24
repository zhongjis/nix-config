{pkgs, ...}: {
  myHomeManager.bundles.general.enable = true;
  myHomeManagerLinux.bundles.linux.enable = true;

  programs.git.userName = "zhongjis";
  programs.git.userEmail = "zhongjie.x.shen@gmail.com";

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.
  home.packages = with pkgs; [];
  home.file = {};
}
