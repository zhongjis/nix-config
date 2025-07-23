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
      # ai
      claude-code

      # ai-mcps
      mcp-k8s-go
      fluxcd-operator-mcp

      # nix
      colmena

      # db
      mongosh
      postgresql

      # db client
      mongodb-compass
      dbeaver-bin
    ]
    ++ [
    ];
}
