{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    sops
  ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ../../secrets/ssh.yaml;
    validateSopsFiles = true;
  };

  systemd.user.services.mbsync.Unit.After = lib.mkIf pkgs.stdenv.isLinux ["sops-nix.service"];
}
