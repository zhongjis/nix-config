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

    # homelab
    "homelab/private_key" = {
      path = "${config.home.homeDirectory}/.ssh/homelab";
    };
    "homelab/public_key" = {
      path = "${config.home.homeDirectory}/.ssh/homelab.pub";
    };
  };

  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github-com" = {
      host = "github.com";
      hostname = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
          AddKeysToAgent = "yes";
        };
      in
        baseOptions // darwinKeychainOption;
    };
    "github-enterprise" = {
      host = "github-enterprise";
      hostname = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
      extraOptions = let
        baseOptions = {
          PreferredAuthentications = "publickey";
          AddKeysToAgent = "yes";
        };
      in
        baseOptions // darwinKeychainOption;
    };
    "git-corp-adobe-com" = {
      host = "git.corp.adobe.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
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
