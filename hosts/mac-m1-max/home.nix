{
  lib,
  pkgs,
  ...
}: {
  myHomeManager.bundles.general.enable = true;
  myHomeManagerDarwin.bundles.darwin.enable = true;

  programs.git.userName = "zshen";
  programs.git.userEmail = "zshen@adobe.com";

  home.username = "zshen";
  home.homeDirectory = lib.mkForce "/Users/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.
  home.packages = with pkgs; [];
  home.file = {};
}
