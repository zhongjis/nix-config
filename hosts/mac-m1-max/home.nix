{
  lib,
  pkgs,
  ...
}: {
  myHomeManager = {
    bundles.general.enable = true;
    bundles.darwin.enable = true;
  };

  home.username = "zshen";
  home.homeDirectory = lib.mkForce "/Users/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
  ];

  home.file = {
  };
}
