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
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github-com" = {
      host = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
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
  };
}
