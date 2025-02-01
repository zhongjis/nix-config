{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
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
    "api_keys_for_ai" = {};
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
