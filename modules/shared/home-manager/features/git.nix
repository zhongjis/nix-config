{
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;

    # configure username and email in home.nix
    userName = lib.mkDefault "zhongjis";
    userEmail = lib.mkDefault "zhongjie.x.shen@gmail.com";

    aliases = {};

    attributes = [
      "push.default current"
    ];
  };

  home.packages = with pkgs; [
    # git-agecrypt
  ];
}
