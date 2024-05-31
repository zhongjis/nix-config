{
  pkgs,
  inputs,
  ...
}: {
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # services.xserver.videoDrivers = ["nvidia"];
  # hardware.nvidia.modesetting.enable = true;

  # hardware.nvidia.prime = {
  #   offload = {
  #     enable = true;
  #     enableOffloadCmd = true;
  #   };

  #   # run `nix shell nixpkgs#pciutils -c lspci | grep ' VGA '` to findout
  #   # integrated
  #   intelBusId = "PCI:0:0:2";

  #   # dedicated
  #   nvidiaBusId = "";

  #   # cmd: $ nvidia-offload some-game
  # };
}
