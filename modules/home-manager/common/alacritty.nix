{ pkgs, config, lib, systemName, ... }:
let
  fontSize =
    if systemName == "mac-m1-max" then
      18
    else 13;
in
{
  options = {
    alacritty.enable =
      lib.mkEnableOption "enables alacritty";
  };

  config = lib.mkIf config.alacritty.enable {
    programs.alacritty = {
      enable = true;
      # catppuccin.enable = true;
      # catppuccin.flavour = "mocha";

      settings = {
        live_config_reload = true;

        shell = {
          program = "${lib.getExe pkgs.zsh}";
          args = [ "-l" "-c" "tmux attach || tmux new-session -d -s home && tmux attach -t home" ];
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
          opacity = 0.95;
          padding = {
            x = 18;
            y = 18;
          };
        };

        env = {
          TERM = "xterm-256color";
        };

        colors = {
          primary = {
            background = "0x002b36";
            foreground = "0x839496";
          };
          normal = {
            black = "0x073642";
            red = "0xdc322f";
            green = "0x859900";
            yellow = "0xb58900";
            blue = "0x268bd2";
            magenta = "0xd33682";
            cyan = "0x2aa198";
            white = "0xeee8d5";
          };
          bright = {
            black = "0x002b36";
            red = "0xcb4b16";
            green = "0x586e75";
            yellow = "0x657b83";
            blue = "0x839496";
            magenta = "0x6c71c4";
            cyan = "0x93a1a1";
            white = "0xfdf6e3";
          };
        };
      };
    };
  };
}
