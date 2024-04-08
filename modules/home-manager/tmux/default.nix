{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    newSession = false;
    historyLimit = 100000;
    clock24 = true;
    extraConfig = ''
      # true color https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

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
