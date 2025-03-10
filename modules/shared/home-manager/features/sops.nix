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
    "github_com_zhongjis/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
    };
    "github_com_zhongjis/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_com_zhongjis.pub";
    };

    # github - adobe
    "github_adobe_zshen/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
    };
    "github_adobe_zshen/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_adobe_zshen.pub";
    };

    # liveaccess - adobe
    "liveaccess_adobe_zshen/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/liveaccess_adobe_zshen";
    };
    "liveaccess_adobe_zshen/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/liveaccess_adobe_zshen.pub";
    };

    # liveaccess - adobe
    "vultr_com/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/vultr_com";
    };
    "vultr_com/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/vultr_com.pub";
    };

    "api_keys_for_ai" = {};
  };

  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
