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

      # **java8**
      # (maven.override {jdk_headless = jdk8;})
      # jdk8
      # tomcat9

      # kube
      kubectl
      kustomize
      kubectx
      yq # format output formatting

      # git
      pre-commit

      # Hashicorp
      terraform
      # terraform-docs
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
    ]
    ++ stable_pkgs;

  homebrew = {
    brews = [
      "maven"
      "openjdk@17"
      "kubelogin"
    ];

    casks = [
      "docker-desktop"

      # util
      "dash"
      "devtoys"

      # ide
      "intellij-idea"
      "phpstorm"
      "cursor"
      "zed"

      "cursor-cli"

      "mongodb-compass"
      "dbeaver-community"
    ];
  };
}
