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
    defaultNetwork.settings.dns_enabled = true;
  };

  # Useful other development tools
  environment.systemPackages = [
    pkgs.podman-compose
    pkgs.stable.podman-desktop
  ];
}
