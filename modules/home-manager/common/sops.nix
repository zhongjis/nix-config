{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "%r/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../secrets.yaml;
    validateSopsFiles = true;

    secrets = {
      "private_keys/github_com_zhongjis".path = "${config.xdg.configHome}/.ssh/github_com_zhongjis";
      "private_keys/github_adobe_zshen".path = "%r/.ssh/github_adobe_zshen";
    };
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
