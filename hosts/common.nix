{
  pkgs,
  inputs,
  ...
}: let
  font_list = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inter
    font-awesome
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "JetBrainsMono"
      ];
    })
  ];
in {
  programs.zsh.enable = true;

  fonts.packages = font_list;

  environment.systemPackages = with pkgs.unstable; [
    nixd
    unzip
  ];

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
