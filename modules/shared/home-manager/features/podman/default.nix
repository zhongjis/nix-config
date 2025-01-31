{pkgs, ...}: {
  imports = [
    ./open-webui.nix
  ];
  home.packages = with pkgs; [
    passt
  ];

  services.podman = {
    enable = true;
    enableTypeChecks = true;
    autoUpdate.enable = true;
    networks.shared = {
      autoStart = true;
      description = "Default network to be shared";
      subnet = "192.168.20.0/24";
      gateway = "192.168.20.1";
      driver = "bridge";
      internal = false;
      extraPodmanArgs = [
        "--ipam-driver host-local"
      ];
    };
  };
}
