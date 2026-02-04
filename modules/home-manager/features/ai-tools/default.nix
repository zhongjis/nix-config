{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./profile-option
    ./general
    ./opencode
    ./claude-code
  ];
}
