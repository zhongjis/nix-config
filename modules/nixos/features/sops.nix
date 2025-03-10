{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.packages = with pkgs; [
    sops
  ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../../secrets.yaml;
    validateSopsFiles = true;
  };

  sops.secrets = {
    # github - personal
    "freshrss/default-user-password" = {};
    "freshrss/db-password" = {};
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
