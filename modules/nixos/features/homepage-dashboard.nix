{config, ...}: let
  cfg = config.services.homepage-dashboard;
in {
  services.homepage-dashboard = {
    enable = true;
  };

  services.nginx = {
    virtualHosts."dashboard.zshen.me" = {
      serverName = "dashboard.zshen.me";
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8082";
        recommendedProxySettings = true;
      };
    };
  };
}
