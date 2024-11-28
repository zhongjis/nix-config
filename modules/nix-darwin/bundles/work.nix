{pkgs, ...}: let
  stable_pkgs = with pkgs.stable; [
    # placeholder
  ];
in {
  environment.systemPackages = with pkgs;
    [
      mongosh
      terraform-versions."1.9.8"

      # **java**
      maven
      jdk

      php

      kubectl
      kubelogin

      vault

      python312
      python312Packages.pip

      redis

      azure-cli
      awscli2
      gh

      # fonts
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "Iosevka"
          "FiraCode"
          "DroidSansMono"
          "Agave"
        ];
      })
      font-awesome
      sketchybar-app-font
      cm_unicode
      corefonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      inter
      font-awesome
    ]
    ++ unstable_pkgs;
}
