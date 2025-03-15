{
  config,
  inputs,
  ...
}: let
  cfg = config.services.portainer;
in {
  services.nginx = {
    virtualHosts."portainer.zshen.me" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "https://localhost:${builtins.toString cfg.port}";
        recommendedProxySettings = true;
      };
    };
  };
}
