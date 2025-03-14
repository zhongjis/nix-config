{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    sops
  ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../../secrets.yaml;
    validateSopsFiles = true;
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
