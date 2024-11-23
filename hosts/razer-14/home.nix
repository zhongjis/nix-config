{pkgs, ...}: {
  imports = [
    ../../modules/home-manager
  ];

  myHomeManager = {
    bundles.general.enable = true;
    bundles.linux.enable = true;
    bundles.gaming.enable = true;
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
  ];

  home.file = {};
}
