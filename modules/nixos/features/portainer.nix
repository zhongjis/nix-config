{config, ...}: let
  cfg = config.services.homepage-dashboard;
in {
  services.homepage-dashboard = {
    enable = true;
  };
  services.portainer = {
    enable = true; # Default false

    version = "latest"; # Default latest, you can check dockerhub for
    # other tags.

    openFirewall = "false"; # Default false, set to 'true' if you want
    # to be able to access via the port on
    # something other than localhost.

    port = 9443; # Sets the port number in both the firewall and
    # the docker container port mapping itself.
  };

  services.nginx = {
    virtualHosts."portainer.zshen.me" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8082";
        recommendedProxySettings = true;
      };
    };
  };
}
