{
  pkgs,
  lib,
  isDarwin,
  ...
}: {
  imports = [
    ./common
    ./linux
    ./darwin
  ];

  common.enable = lib.mkDefault true;

  linux-hm-modules.enable =
    if isDarwin
    then lib.mkDefault false
    else lib.mkDefault true;
  darwin-hm-modules.enable =
    if isDarwin
    then lib.mkDefault true
    else lib.mkDefault false;

  xdg.enable = true;

  home.packages = with pkgs; [
    sops
    obsidian
    bitwarden

    awscli2

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
