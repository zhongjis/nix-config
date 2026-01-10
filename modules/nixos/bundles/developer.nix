{
  inputs,
  pkgs,
  lib,
  ...
}: {
  myNixOS.podman.enable = lib.mkDefault true;
  myNixOS.docker.enable = lib.mkDefault false;
  myNixOS.kubernetes.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs;
    [
      # nix
      inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena

      gh
      graphite-cli

      # db
      mongosh
      postgresql

      # db client
      mongodb-compass
      dbeaver-bin

      insomnia
    ]
    ++ [
    ];
}
