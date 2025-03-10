{...}: {
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

      locations = {
        "/freshrss" = {
          root = "/zfs2/servers/freshrss";
        };
      };
    };
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://zshen.art/freshrss";
    dataDir = "/zfs2/servers/freshrss";
    passwordFile = "/zfs2/servers/freshrssPassword";
  };
}
