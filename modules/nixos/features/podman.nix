{pkgs, ...}: {
  virtualisation.libvirtd.enable = true;
  # Enable common container config files in /etc/containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [
        "--filter=until=24h"
        "--filter=label!=important"
      ];
    };
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [53];

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    passt

    podman-compose
    stable.podman-desktop
  ];

  virtualisation.oci-containers.backend = "podman";
}
