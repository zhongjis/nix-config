{
  pkgs,
  lib,
  config,
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
  options = {
    zsh.enable =
      lib.mkEnableOption "enables zsh";
  };

  config = lib.mkIf config.zsh.enable {
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
          "terraform"
          "vi-mode"
          "autojump"
          "sublime-merge"
          # "mvn"
          # "kubectl"
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
      '';
    };

    programs.starship = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      enableZshIntegration = true;

      settings = {
      };
    };

    programs.bat = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };

    programs.carapace = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = true;
      extraOptions = [
        "--group-directories-first"
        "--long"
        "--no-user"
      ];
    };

    home.packages = with pkgs; [
      autojump
    ];
  };
}
