{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # enableAutoSuggestions = true;
    dotDir = ".config/zsh";
    # autosuggestions = {
    #     enable = true;
    #     highlight = true;
    # };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "terraform" "vi-mode"];
      theme = "robbyrussell";
    };
    shellAliases = {
        ls = "eza --long --header --git";
        la = "eza --long --header --git -a";
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
