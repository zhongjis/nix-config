{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    newSession = true;
  };
}
