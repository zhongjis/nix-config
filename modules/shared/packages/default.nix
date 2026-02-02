{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./cli-tools.nix
    ./dev-tools.nix
    ./fonts.nix
  ];
}
