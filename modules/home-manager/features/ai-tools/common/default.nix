{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./instructions
    ./skills
    ./mcp
  ];
}
