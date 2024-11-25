{
  pkgs,
  lib,
  currentSystemName,
  ...
}: let
  fontSize =
    if currentSystemName == "mac-m1-max"
    then 18
    else 13;
in {
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;

    settings = {
      enable_audio_bell = "no";
      confirm_os_window_close = "0";

      cursor_text_color = "background";

      font_family = "FiraCode Nerd Font Propo";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = fontSize;

      hide_window_decorations = "yes";
      window_padding_width = 18;
      background_blur = "20";

      shell = "${lib.getExe pkgs.zsh} -l -c 'tmux attach || tmux new-session -d -s home \"fastfetch; exec $SHELL\" && tmux attach -t home'";
    };
  };
}
