{ pkgs, lib, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      live_config_reload = true;

      shell = {
        program = "${lib.getExe pkgs.zsh}";
        args = ["-l" "-c" "tmux attach || tmux new-session -d -s home"];
      };
      cursor.style.blinking = "Always";
      font = {
        normal.family = "Firacode Nerd Font";
        bold.style = "Bold";
        size = 13;
      };
      window = {
        decorations = "buttonless";
        dynamic_padding = false;
        opacity = 0.95;
        padding = {
          x = 18;
          y = 18;
        };
      };
    };
  };
}
