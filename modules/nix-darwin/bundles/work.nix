{pkgs, ...}: let
  unstable_pkgs = with pkgs.unstable; [
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
    ]
    ++ unstable_pkgs;
}
