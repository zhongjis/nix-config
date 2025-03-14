{
  inputs,
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sops
  ];

  sops = {
    age.keyFile = "/home/zshen/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";

    validateSopsFiles = true;
  };
}
