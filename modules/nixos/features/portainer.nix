{config, ...}: let
  cfg = config.services.portainer;
in {
  services.portainer = {
    enable = true; 
    version = "latest"; 
    openFirewall = "false"; 
    port = 9443;
  };

  services.nginx = {
    virtualHosts."portainer.zshen.me" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:${cfg.port}";
        recommendedProxySettings = true;
      };
    };
  };
}
