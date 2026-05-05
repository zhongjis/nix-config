{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package =
      if pkgs.stdenv.isDarwin
      then null
      else pkgs.ghostty; # package managed by system
    settings = {
      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # font
      font-size = 12;

      # window
      window-decoration = false;
      window-padding-x = 18;
      window-padding-y = 12;
      title = "Ghostty";

      # init
      initial-command = "zsh -l -c 'tmux attach || tmux new-session -d -s home \"${pkgs.fastfetch}/bin/fastfetch; exec $SHELL\" && tmux attach -t home'";
      confirm-close-surface = false;
      background-opacity = 0.9;
      keybind = [
        "alt+backspace=text:\x1b\x7f"
      ];
    };
  };
}
