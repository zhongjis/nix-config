{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    ghostty
  ];

  home.file."${config.xdg.configHome}/ghostty/config" = {
    text =
      /*
      toml
      */
      ''
        font-family = JetBrainsMono Nerd Font
        font-size = 14
        theme = catppuccin-mocha
        window-decoration = false
        window-padding-x = 18
        window-padding-y = 12
        initial-command = zsh -l -c 'tmux attach || tmux new-session -d -s home \"&& tmux attach -t home'
        confirm-close-surface = false
        background-opacity = 0.9
      '';
  };
}
