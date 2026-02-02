{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../shared/packages
  ];
  myNixOS.podman.enable = lib.mkDefault true;
  myNixOS.docker.enable = lib.mkDefault false;
  myNixOS.kubernetes.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs;
    [
      # nix
      inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena

      graphite-cli

      # db
      postgresql

      # db client
      mongodb-compass
      dbeaver-bin

      insomnia
    ]
    ++ [
    ];
}
