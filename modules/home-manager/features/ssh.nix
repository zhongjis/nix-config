{
  pkgs,
  config,
  ...
}: {
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
        conditionalOptions =
          if pkgs.stdenv.isLinux
          then {}
          else {
            UseKeychain = "yes";
          };
      in
        baseOptions // conditionalOptions;
    };
  };
}
