{pkgs, ...}: let
  stable_pkgs = with pkgs.stable; [];
in {
  environment.systemPackages = with pkgs;
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
    ]
    ++ stable_pkgs;
}
