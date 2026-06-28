{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./instructions
    ./skills
    ./mcp
    ./lsp.nix
  ];
}
