{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = "gruvbox-dark-hard";
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "rofi-toggle" ''
    #!/usr/bin/env bash

    if pgrep -x "rofi" > /dev/null; then
        # Rofi is running, kill it
        pkill rofi 
    else
        # Rofi not running, launch it
        rofi -show combi -modes combi -combi-modes "window,drun,run"
        sleep 0.2           # Small delay to let Rofi open
        hyprctl dispatch focuswindow active
    fi
  '')
  ];
}
