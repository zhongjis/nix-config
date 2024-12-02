{pkgs, ...}: let
  unstable_pkgs = with pkgs; [];
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
    ++ unstable_pkgs;
}
