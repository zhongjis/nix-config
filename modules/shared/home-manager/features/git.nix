{pkgs, ...}: {
  programs.git = {
    enable = true;

    # configure username and email in home.nix
    # userName = "zhongjis";
    # userEmail = "zhongjie.x.shen@gmail.com";

    aliases = {};

    attributes = [
      "push.default current"
    ];
  };

  home.packages = with pkgs; [
    # git-agecrypt
  ];
}
