{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    newSession = true;
    historyLimit = 100000;
    clock24 = true;
    extraConfig = ''
    set -g detach-on-destroy off     # don't exit from tmux when closing a session \n
    set -g renumber-windows on       # renumber all windows when any window is closed \n
    set -g status-left-length 15     # could be any number
    '';
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.dracula;
        extraConfig = ''
        set -g @plugin 'dracula/tmux'
        set -g @dracula-show-powerline false
        set -g @dracula-show-flags false
        set -g @dracula-show-left-icon session
        set -g @dracula-plugins "battery"
        '';
      }
    ];
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "tmux-sessionizer" ''
    ${builtins.readFile ./tmux-sessionizer.sh}
  '')
  ];
}
