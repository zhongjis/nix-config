{pkgs, ...}: let
in {
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;
    # Settings a mess. using hm to manage it
    # settings = {};
  };
}
