{...}: let
in {
  # NOTE: this module is depending on dify docker compose file
  # make sure to expose dify's nginx port by setting
  # EXPOSE_NGINX_PORT=8080
  # EXPOSE_NGINX_SSL_PORT=8443
  # in its .env file

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
