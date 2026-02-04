{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./shared
    ./claude-code-only
    ./opencode
    ./claude-code
  ];
}
