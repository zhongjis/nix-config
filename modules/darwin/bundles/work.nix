{
  pkgs,
  inputs,
  ...
}: let
  stable_pkgs = with pkgs.stable; [
  ];
in {
  environment.systemPackages = with pkgs;
    [
      mongosh

      php

      # **java17**
      (maven.override {jdk_headless = jdk17;})
      jdk17

      # kube
      kubectl
      kustomize
      kubectx
      yq # format output formatting

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

      kubelogin
    ]
    ++ stable_pkgs;

  homebrew = {
    brews = [];

    casks = [
      "docker"
      "dash"
      "devtoys"
      "intellij-idea"
      "mongodb-compass"
      "sublime-merge@dev"
      "cursor"
    ];
  };
}
