{
  config,
  inputs,
  ...
}: let
  cfg = config.services.portainer;
in {
  imports = [
    inputs.portainer-on-nixos.nixosModules.portainer
  ];

  services.portainer = {
    enable = true;
    version = "latest";
    openFirewall = false;
    port = 9443;
  };

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
