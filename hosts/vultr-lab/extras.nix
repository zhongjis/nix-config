{config, ...}: let
  sopsFile = ../../secrets/freshrss.yaml;
in {
  sops.secrets = {
    # github - personal
    freshrss_user_password = {
      inherit sopsFile;
    };
    freshrss_db_password = {
      inherit sopsFile;
    };
  };

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
    };

    virtualHosts."rss.zshen.me" = {
      serverName = "rss.zshen.me";

      default = false;
      enableACME = true;
      forceSSL = true;
    };
  };

  services.freshrss = {
    enable = true;
    passwordFile = config.sops.secrets.freshrss_user_password.path;
    virtualHost = "rss.zshen.me";
    baseUrl = "https://rss.zshen.me";

    database = {
      type = "pgsql";
      passFile = config.sops.secrets.freshrss_db_password.path;
    };

    extensions = [];
  };
}
