{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sops.enable = true;
  myNixOS.nh.enable = true;
  myNixOS.docker.enable = true;
  myNixOS.nginx.enable = true;

  # xremap - bug. when xremap.nix is not enabled. for some reason this have to be set to false
  services.xremap.enable = false;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.unzip
  ];
}
