{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./settings.nix
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
