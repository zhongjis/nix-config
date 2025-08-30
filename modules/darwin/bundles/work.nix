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
      # (maven.override {jdk_headless = jdk17;})
      # jdk17

      # **java17**
      (maven.override {jdk_headless = jdk8;})
      jdk8
      tomcat9

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
      # azure-cli
      # azure-functions-core-tools

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
      "docker-desktop"
      "dash"
      "devtoys"
      "intellij-idea"
      "phpstorm"
      "mongodb-compass"
      "sublime-merge@dev"
      "cursor"
      "dbeaver-community"
      "postman"
    ];
  };
}
