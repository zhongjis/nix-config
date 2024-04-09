{ pkgs, ... }:

{
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
        "terraform"
        "vi-mode"
        # "autojump"
        "sublime" 
        "sublime-merge"
        "mvn"
        "kubectl"
      ];
      theme = "refined";
    };
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      save = 10000;
      size = 10000;
      share = true;
    };
    shellAliases = {
        ls = "eza --long --header --git";
        la = "eza --long --header --git -a";
        nixswitch = "sudo nixos-rebuild switch --flake ~/nix-config/#default";
        nixtest = "sudo nixos-rebuild test --flake ~/nix-config/#default";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    eza
  ];
}
