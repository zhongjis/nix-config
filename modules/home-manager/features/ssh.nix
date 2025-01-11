{config, ...}: {
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    hostname = "github.com";
    identifyFile = "${config.home.homeDirectory}/.ssh/github_com_zhongjis";
    extraConfig = ''
      PreferredAuthentications publickey
    '';
  };
}
