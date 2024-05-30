{
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}: let
  keyboardCmd =
    if isDarwin
    then "xclip -in -selection clipboard"
    else "tmux show-buffer | wl-copy";
in {
  options = {
    tmux.enable =
      lib.mkEnableOption "enables tmux";
  };

  config = lib.mkIf config.tmux.enable {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 0;
      keyMode = "vi";
      newSession = false;
      historyLimit = 100000;
      clock24 = true;
      extraConfig = ''
        # true color
        # https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",xterm-256color:RGB"

        # Undercurl
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

        # copy to clipboard
        bind-key -T copy-mode-vi v send -X begin-selection
        bind-key -T copy-mode-vi V send -X select-line
        bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel '${keyboardCmd}'

        # other settings
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
  };
}
