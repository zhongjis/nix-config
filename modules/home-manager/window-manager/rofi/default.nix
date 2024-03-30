{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "rofi-toggle" ''
    #!/usr/bin/env bash

    if pgrep -x "rofi" > /dev/null; then
        # Rofi is running, kill it
        pkill rofi 
    else
        # Rofi not running, launch it
        rofi -show drun 
    fi
  '')
  ];

}
