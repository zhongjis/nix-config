{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sops.enable = lib.mkDefault true;
  myNixOS.nh.enable = lib.mkDefault true;
  myNixOS.podman.enable = lib.mkDefault false;
  myNixOS.docker.enable = lib.mkDefault true;
  myNixOS.nginx.enable = lib.mkDefault true;
  myNixOS.homepage-dashboard.enable = lib.mkDefault true;
  myNixOS.portainer.enable = lib.mkDefault true;

  # xremap - bug. when xremap.nix is not enabled. for some reason this have to be set to false
  services.xremap.enable = false;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.unzip
  ];
}
