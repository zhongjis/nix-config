{ ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    newSession = true;
    historyLimit = 100000;
    extraConfig = ''
        set -g detach-on-destroy off     # don't exit from tmux when closing a session \n
        set -g renumber-windows on       # renumber all windows when any window is closed \n
        set -g status-left-length 10 # could be any number
    '';
  };
}
