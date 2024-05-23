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

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    awscli
    gh
    graphviz
    wget
    font-awesome
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
