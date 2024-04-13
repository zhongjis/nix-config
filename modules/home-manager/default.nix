{ lib, ... }:
{
  imports = [
    ./common
    ./window-manager
  ];

  common.enable = lib.mkDefault true;
  window-manager.enable = lib.mkDefault false;
}
