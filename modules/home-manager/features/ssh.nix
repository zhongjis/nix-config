{config, ...}: {
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github-com" = {
      host = "github.com";
      identityFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
      extraOptions = {
        "PreferredAuthentications" = "publickey";
      };
    };
  };
}
