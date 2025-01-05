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
    opencl.enable = true;
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

  # Workaround for HIP GPU acceleration on AMD APUs
  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  ];

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
  ];
}
