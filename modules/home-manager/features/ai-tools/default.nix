{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./profile-option
    ./shared
    ./claude-code-only
    ./opencode
    ./claude-code
  ];
}
