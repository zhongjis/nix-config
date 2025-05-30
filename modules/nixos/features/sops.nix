{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sops
    gnupg
  ];

  sops = {
    age.keyFile = lib.mkDefault "/home/zshen/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";

    validateSopsFiles = true;
  };
}
