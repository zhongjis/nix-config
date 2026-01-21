{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./mcp.nix
    ./settings.nix
  ];

  programs.claude-code = {
    enable = true;
  };
}
