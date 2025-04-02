{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sops.enable = lib.mkDefault true;
  myNixOS.nh.enable = lib.mkDefault true;

  # xremap - bug. when xremap.nix is not enabled. for some reason this have to be set to false
  services.xremap.enable = false;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.k3s
    pkgs.cifs-utils
    pkgs.nfs-utils
    pkgs.git
    pkgs.neovim
    pkgs.unzip
  ];
}
