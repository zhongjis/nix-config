{
  pkgs,
  inputs,
  ...
}: let
  stable_pkgs = with pkgs.stable; [];
in {
  environment.systemPackages = with pkgs;
    [
      mongosh

      php

      # **java**
      maven
      jdk

      # kube
      kubectl
      kubelogin

      # git
      pre-commit

      # Hashicorp
      terraform
      terraform-docs
      vault

      # python
      python312
      python312Packages.pip

      redis

      # azure
      azure-cli
      azure-functions-core-tools

      # aws
      awscli2

      gh

      charles

      code-cursor
    ]
    ++ stable_pkgs;

  homebrew = {
    brews = [
      "bitwarden-cli"
    ];

    casks = [
      "dash"
      "devtoys"
      "intellij-idea"
      "mongodb-compass"
      "sublime-merge@dev"
    ];
  };
}
