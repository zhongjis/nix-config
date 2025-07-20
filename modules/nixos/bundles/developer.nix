{
  inputs,
  pkgs,
  lib,
  ...
}: {
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
      mongodb-compass
      mongosh
      dbeaver-bin
    ]
    ++ [
    ];
}
