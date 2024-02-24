{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "terraform" ];
      theme = "robbyrussell";
    };
  };
}
