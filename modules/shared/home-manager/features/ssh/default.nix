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
  imports = [./adobe.nix];

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

  programs.ssh.enable = true;
  programs.ssh = {
    addKeysToAgent = "yes";
    controlMaster = "auto";
    forwardAgent = true;
    extraConfig = ''
      IdentityFile: ${config.home.homeDirectory}/.ssh/github_com_zhongjis;
      ServerAliveInterval: 60
      HostkeyAlgorithms: +ssh-rsa
      PubkeyAcceptedAlgorithms : +ssh-rsa
    '';
  };
  programs.ssh.matchBlocks = {
    "github.com-zhongjis" = {
      host = "github.com-zhongjis";
      hostname = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
      identitiesOnly = true;
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
          AddKeysToAgent = "yes";
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
          AddKeysToAgent = "yes";
        };
      in
        baseOptions // darwinKeychainOption;
    };
  };
}
