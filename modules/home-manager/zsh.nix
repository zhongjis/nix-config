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
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "terraform" "vi-mode"];
      theme = "robbyrussell";
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
