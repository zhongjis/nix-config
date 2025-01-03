{
  pkgs,
  config,
  lib,
  ...
}: {
  # https://nixos.wiki/wiki/AMD_GPU
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = ["amdgpu"];

  environment.systemPackages = with pkgs; [
    pciutils
    # gwe # not supported for wayland yet
  ];
}
