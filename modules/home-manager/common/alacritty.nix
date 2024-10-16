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
    alacritty.enable =
      lib.mkEnableOption "enables alacritty";
  };

  config = lib.mkIf config.alacritty.enable {
    programs.alacritty = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      settings = {
        live_config_reload = true;

        shell = {
          program = "${lib.getExe pkgs.zsh}";
          args = ["-l" "-c" "tmux attach || tmux new-session -d -s home \"fastfetch; exec $SHELL\" && tmux attach -t home"];
        };

        cursor.style.blinking = "Always";

        font = {
          normal.family = "Firacode Nerd Font";
          bold.style = "Bold";
          size = fontSize;
        };

        window = {
          decorations = "buttonless";
          dynamic_padding = false;
          opacity = 0.8;
          blur = true;
          padding = {
            x = 18;
            y = 18;
          };
        };

        env = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
