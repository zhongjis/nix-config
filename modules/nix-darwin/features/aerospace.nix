{pkgs, ...}: let
in {
  services.aerospace = {
    enable = true;
    package = pkgs.unstable.aerospace;
    # Settings a mess. using hm to manage it
    # settings = {};
  };
}
