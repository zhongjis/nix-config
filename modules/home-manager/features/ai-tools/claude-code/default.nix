{
  lib,
  pkgs,
  ...
}: {
  imports = [
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
