{pkgs, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "zhongjie.x.shen@gmail.com";
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;

    # placeholder for now
    virtualHosts."zshen.art" = {
      serverName = "zshen.art";

      default = true;
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://zshen.dev";
        recommendedProxySettings = true;
      };
    };
  };
}
