{
  config,
  inputs,
  ...
}: let
in {
  virtualisation.oci-containers = {
    containers.portainer-ce = {
      image = "portainer/portainer-ce:latest";
      volumes = [
        "portainer_data:/data"
        "/var/run/docker.sock:/var/run/docker.sock"
        # "/run/podman/podman.sock:/var/run/docker.sock"
        "/etc/localtime:/etc/localtime"
      ];
      ports = ["9443:9443"];
      autoStart = true;
      extraOptions = [
        "--pull=always"
        "--restart=unless-stopped"
        "--rm=false"
      ];
    };
    # containers.portainer-agent = {
    #   image = "portainer/agent:latest";
    #   volumes = [
    #     "/var/run/docker.sock:/var/run/docker.sock"
    #     "/var/lib/docker/volumes:/var/lib/docker/volumes"
    #     "/:/host"
    #   ];
    #   ports = ["9001:9001"];
    #   autoStart = true;
    #   extraOptions = [
    #     "--pull=always"
    #     "--restart=unless-stopped"
    #     "--rm=false"
    #   ];
    # };
  };

  services.nginx = {
    virtualHosts."portainer.zshen.me" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "https://localhost:9443";
        recommendedProxySettings = true;
      };
    };
  };
}
