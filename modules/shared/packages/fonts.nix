{
  pkgs,
  lib,
  ...
}: {
  fonts.packages = with pkgs;
    [
      # Nerd Fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.agave

      # Icon fonts
      font-awesome

      # System fonts
      cm_unicode
      corefonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      inter
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      sketchybar-app-font
    ];
}
