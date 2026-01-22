{
  pkgs,
  config,
  ...
}: let
  darwinKeychainOption =
    if pkgs.stdenv.isDarwin
    then {
      UseKeychain = "yes";
    }
    else {};
in {
  sops.secrets = {
    # github - personal
    "github_com_zhongjis/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
    };
    "github_com_zhongjis/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/github_com_zhongjis.pub";
    };

    # homelab
    "homelab/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/homelab";
    };
    "homelab/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/homelab.pub";
    };
  };

  # temp fix. more details see https://github.com/Mic92/sops-nix/issues/890
  launchd.agents.sops-nix = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = pkgs.lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  # NOTE: example for entry order
  # "*" = lib.hm.dag.entryBefore ["*.example.com"] {
  programs.ssh.matchBlocks = {
    "*" = {
      addKeysToAgent = "yes";
      controlMaster = "auto";
      forwardAgent = true;
      serverAliveInterval = 60;
      # NOTE: never figure out a way to put this under host *. so just set it as override for now
      extraOptions = {
        HostkeyAlgorithms = "+ssh-rsa";
        PubkeyAcceptedAlgorithms = "+ssh-rsa";
      };
    };
    "github.com-zhongjis" = {
      host = "github.com";
      hostname = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
      identitiesOnly = true;
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
        };
      in
        baseOptions // darwinKeychainOption;
    };
    "homelab" = {
      host = "192.168.50.103 192.168.50.104";
      identityFile = "${config.home.homeDirectory}/.ssh/homelab";
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
        };
      in
        baseOptions // darwinKeychainOption;
    };
    "raspberrypi4b" = {
      host = "192.168.50.2";
      identityFile = "${config.home.homeDirectory}/.ssh/homelab";
      identitiesOnly = true;
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
        };
      in
        baseOptions // darwinKeychainOption;
    };
  };
}
