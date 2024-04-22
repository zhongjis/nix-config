{ pkgs, lib, config, ... }:

{
  options = {
    zsh.enable =
      lib.mkEnableOption "enables zsh";
  };

  config = lib.mkIf config.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
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
          "mvn"
          "kubectl"
          "kubectx" # TODO: verify it is working
        ];
        theme = "refined";
      };
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        save = 10000;
        size = 10000;
      };
      shellAliases = {
        cat = "bat";
        ls = "eza --color=always --long --git --no-user --no-permissions";
        la = "eza --color=always --long --git --no-user --no-permissions -a";
        nixswitch = "sudo nixos-rebuild switch --flake ~/nix-config/#thinkpad-t480";
        nixtest = "sudo nixos-rebuild test --flake ~/nix-config/#thinkpad-t480";
      };
      initExtra = ''
        ${builtins.readFile ./catppuccin_mocha-zsh-syntax-highlighting.zsh}
      '';
    };

    programs.bat = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavour = "mocha";
    };

    home.packages = with pkgs; [
      eza
      autojump
    ];
  };
}
