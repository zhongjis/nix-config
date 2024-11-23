{
  pkgs,
  currentSystemName,
  ...
}: let
  oswitchCMD = "nh os switch . --hostname ${currentSystemName}";
  otestCMD = "nh os test . --hostname ${currentSystemName}";
  hswitchCMD =
    if currentSystemName == "mac-m1-max"
    then "nh home switch . -c zshen-mac"
    else "nh home switch . -c zshen-linux";
  htestCMD =
    if currentSystemName == "mac-m1-max"
    then "nh home test . -c zshen-mac"
    else "nh home test . -c zshen-linux";
in {
  programs.zsh = {
    enable = true;
    # enableCompletion = true;
    dotDir = ".config/zsh";
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
    };
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "gh"
        "sublime-merge"
        "mvn"
      ];
    };
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      save = 10000;
      size = 10000;
    };
    shellAliases = {
      cat = "bat -p";
      oswitch = oswitchCMD;
      otest = otestCMD;
      hswitch = hswitchCMD;
      htest = htestCMD;
    };
    initExtra = ''
      ${builtins.readFile ./catppuccin_mocha-zsh-syntax-highlighting.zsh}
      bindkey -v
    '';
  };
}
