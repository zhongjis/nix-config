{pkgs, ...}: let
  unstable_pkgs = with pkgs; [
    # placeholder
  ];
in {
  environment.systemPackages = with pkgs.stable;
    [
      mongosh
      terraform

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
