{
  pkgs,
  config,
  lib,
  currentSystemName,
  ...
}: let
  fontSize =
    if currentSystemName == "mac-m1-max"
    then 18
    else 13;
in {
  options = {
    kitty.enable =
      lib.mkEnableOption "enables kitty";
  };

  config = lib.mkIf config.kitty.enable {
    programs.kitty = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      shellIntegration.enableZshIntegration = true;

      settings = {
        confirm_os_window_close = "0";

        font_family = "FiraCode Nerd Font";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
        font_size = fontSize;

        hide_window_decorations = "yes";
        window_padding_width = 18;
        background_opacity = "0.8";
        background_blur = "20";

        shell = "${lib.getExe pkgs.zsh} -l -c 'tmux attach || tmux new-session -d -s home \"fastfetch; exec $SHELL\" && tmux attach -t home'";
      };
    };
  };
}
