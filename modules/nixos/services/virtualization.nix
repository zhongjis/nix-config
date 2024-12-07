{pkgs, ...}: {
  virtualisation.libvirtd.enable = true;
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings = {
  #     dns_enabled = true;
  #   };
  # };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    # https://www.howtogeek.com/run-any-app-on-any-linux-distro-with-distrobox/
    distrobox
  ];
}
