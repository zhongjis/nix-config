{
  pkgs,
  config,
  lib,
  ...
}: {
  # https://nixos.wiki/wiki/AMD_GPU
  boot.initrd.kernelModules = ["amdgpu"];
  # someone is saying this is no longer needed
  # services.xserver.videoDrivers = ["amdgpu"];

  environment.systemPackages = with pkgs; [
    pciutils
    # gwe # not supported for wayland yet
  ];
}
