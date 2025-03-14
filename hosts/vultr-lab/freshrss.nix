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

  services.nginx = {
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
    user = "freshrss";

    database = {
      type = "sqlite";
      passFile = config.sops.secrets.freshrss_db_password.path;
    };

    extensions = [];
  };
}
