{
  pkgs,
  isDarwin,
  config,
  inputs,
  ...
}: let
  keyboardCmd =
    if isDarwin
    then "xclip -in -selection clipboard"
    else "tmux show-buffer | wl-copy";
in {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    newSession = false;
    historyLimit = 100000;
    clock24 = true;
    shell = "${pkgs.zsh}/bin/zsh";

    # NOTE: waiting on fix from https://github.com/tmux-plugins/tmux-sensible/pull/75
    plugins = [
      {plugin = inputs.minimal-tmux.packages.${pkgs.system}.default;}
      pkgs.tmuxPlugins.vim-tmux-navigator
    ];

    extraConfig =
      /*
      bash
      */
      ''
        set-option -g status-position top

        unbind r
        bind r source-file ${config.home.homeDirectory}/.config/tmux/tmux.conf

        # Pane movement like vim
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        # True color
        # https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",xterm-256color:RGB"

        # Undercurl
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

        # Copy to clipboard
        bind-key -T copy-mode-vi v send -X begin-selection
        bind-key -T copy-mode-vi V send -X select-line
        bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel '${keyboardCmd}'

        # other settings
        set -g detach-on-destroy off     # don't exit from tmux when closing a session \n
        set -g renumber-windows on       # renumber all windows when any window is closed \n
        set -g status-left-length 15     # could be any number
      '';
  };

  xdg.configFile."tmux/.tmux-cht-command".source = ./scripts/.tmux-cht-command;
  xdg.configFile."tmux/.tmux-cht-languages".source = ./scripts/.tmux-cht-languages;

  home.packages = with pkgs; [
    (writeScriptBin "sessionizer" ''
      ${builtins.readFile ./scripts/tmux-sessionizer.sh}
    '')
    (writeScriptBin "cht" ''
      ${builtins.readFile ./scripts/tmux-cht.sh}
    '')
  ];
}
