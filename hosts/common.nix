{
  pkgs,
  isDarwin,
  ...
}: let
  font_list = with pkgs; [
    noto-fonts
    noto-fonts-cjk
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

  fonts =
    if isDarwin
    then {
      fontDir.enable = true;
      fonts = font_list;
    }
    else {
      packages = font_list;
    };
}
