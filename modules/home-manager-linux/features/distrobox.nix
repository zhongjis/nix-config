{pkgs, ...}: {
  programs.distrobox = {
    enable =
      if pkgs.stdenv.isDarwin
      then false
      else true;
    enableSystemdUnit = true;
    containers = {
      # common-debian = {
      #   additional_packages = "git";
      #   entry = true;
      #   image = "debian:13";
      #   init_hooks = [
      #     "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
      #     "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
      #   ];
      # };
      # office = {
      #   additional_packages = "libreoffice onlyoffice";
      #   clone = "common-debian";
      #   entry = true;
      # };
      python-poetry = {
        image = "3.14.2-alpine3.22";
        init_hooks = "curl -sSL https://install.python-poetry.org | python3 -";
      };
      # random-things = {
      #   clone = "common-debian";
      #   entry = false;
      # };
    };
  };
}
