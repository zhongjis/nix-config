{ lib, ... }:
{
  imports = [
    ./xremap.nix
  ];

  xremap.enable = lib.mkDefault true;
}
