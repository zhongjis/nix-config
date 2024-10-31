{inputs, ...}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "%r/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../secrets.yaml;
    validateSopsFiles = false;

    secrets = {
      "ssh/private_keys/github_com_zhongjis".path = "%r/.ssh/github_com_zhongjis";
      "ssh/private_keys/github_adobe_zshen".path = "%r/.ssh/github_adobe_zshen";
    };
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
