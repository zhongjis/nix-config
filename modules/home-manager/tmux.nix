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
    #!/usr/bin/env bash
    # Your script's content here.
    if [[ $# -eq 1 ]]; then
    	selected=$1
    else
    	selected=$(find ~ ~/personal ~/work -mindepth 1 -maxdepth 1 -type d | fzf)
    fi

    if [[ -z $selected ]]; then
    	exit 0
    fi

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    	tmux new-session -s $selected_name -c $selected
    	exit 0
    fi

    if ! tmux has-session -t=$selected_name 2>/dev/null; then
    	tmux new-session -ds $selected_name -c $selected
    fi

    tmux switch-client -t $selected_name
  '')
  ];
}
