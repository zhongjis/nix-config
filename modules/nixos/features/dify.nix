{...}: let
in {
  services.nginx = {
    virtualHosts."dify.zshen.me" = {
      serverName = "dify.zshen.me";
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };
}
