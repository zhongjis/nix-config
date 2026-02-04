{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./mcp.nix
    ./claude-code
    ./opencode
  ];
}
