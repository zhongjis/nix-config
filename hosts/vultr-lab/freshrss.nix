{
  config,
  lib,
  ...
}: let
  sopsFile = ../../secrets/freshrss.yaml;
  cfg = config.services.freshrss;
  user = "freshrss";
in {
  sops.secrets = {
    # github - personal
    freshrss_user_password = {
      inherit sopsFile;
      owner = lib.mkIf cfg.enable user;
    };
    freshrss_db_password = {
      inherit sopsFile;
      owner = lib.mkIf cfg.enable user;
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
    inherit user;

    database = {
      type = "sqlite";
      passFile = config.sops.secrets.freshrss_db_password.path;
    };

    extensions = [];
  };
}
