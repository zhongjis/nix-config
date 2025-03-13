{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "zhongjie.x.shen@gmail.com";
    };
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts."zshen.art" = {
      serverName = "zshen.art";

      default = true;
      enableACME = true;
      forceSSL = true;
      root = (
        builtins.fetchTarball {
          url = "https://storage.mynixos.com/5/resources/96c8eb7b-758d-4c66-842d-c1ce63bb7f93/site.tar.gz";
          sha256 = "ublnwAsRKl+Sz7XJXE/38el89m3EDPSld4qMwcxqKdo=";
        }
      );

      # locations = {
      #   "/freshrss" = {
      #     root = "/var/lib/freshrss";
      #   };
      # };
    };
  };

  services.freshrss = {
    enable = true;
    passwordFile = config.sops.secrets."freshrss/default-user-password".path;
    # virtualHost = "freshrss.zshen.art";
    baseUrl = "https://zshen.art";

    database = {
      type = "pgsql";
      passFile = config.sops.secrets."freshrss/db-password".path;
    };

    extensions = [];
  };
}
