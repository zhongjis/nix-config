{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./bundle-darwin.nix
    ./aerospace
  ];
}
