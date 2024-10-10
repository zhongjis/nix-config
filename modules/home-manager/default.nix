{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common
    ./window-manager
  ];

  common.enable = lib.mkDefault true;
  window-manager.enable = lib.mkDefault false;

  xdg.enable = true;

  home.packages = with pkgs; [
    awscli2
    fastfetch

    gh
    graphviz
    wget

    # fonts
    font-awesome
    sketchybar-app-font
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "Agave"
        "JetBrainsMono"
      ];
    })
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
