{pkgs, ...}: {
  # https://nixos.wiki/wiki/AMD_GPU
  # https://github.com/xerhaxs/nixos/blob/main/nixosModules/hardware/amdgpu.nix

  boot.initrd.kernelModules = ["amdgpu"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      driversi686Linux.amdvlk
    ];
  };

  hardware.amdgpu = {
    opencl.enable = true; # FIXME: this one was broken
    initrd.enable = true;
    amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };
  };

  # Tell Xorg to use the amd driver
  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
  ];
}
