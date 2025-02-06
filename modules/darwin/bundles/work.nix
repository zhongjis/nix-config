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
    ]
    ++ stable_pkgs;

  homebrew = {
    brews = [
    ];

    casks = [
      # dev tools
      "dash"

      # "docker"

      "charles"
      "devtoys"
      "mongodb-compass"
      "intellij-idea"
      "visual-studio-code"
      "sublime-merge"
      "zed"
      "cursor"
    ];
  };
}
