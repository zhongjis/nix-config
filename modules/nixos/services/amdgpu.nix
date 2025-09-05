{pkgs, ...}: {
  # https://nixos.wiki/wiki/AMD_GPU
  # https://github.com/xerhaxs/nixos/blob/main/nixosModules/hardware/amdgpu.nix

  chaotic.mesa-git.enable = true;

  boot.initrd.kernelModules = ["amdgpu"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau

      rocmPackages.clr
      rocmPackages.clr.icd
    ];
  };

  environment.variables = {
    VDPAU_DRIVER = "radeonsi";
    LIBVA_DRIVER_NAME = "radeonsi";

    # Force radv
    # AMD_VULKAN_ICD = "RADV";
    # VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  # Most software has the HIP libraries hard-coded. Workaround:
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.amdgpu = {
    opencl.enable = true;
    initrd.enable = true;
    amdvlk = {
      enable = false;
      support32Bit.enable = false;
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
