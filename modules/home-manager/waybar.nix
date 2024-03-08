{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    package = null;
    settings = {
    };
  };

  home.packages = with pkgs; [
    rofi
    killall
  ];
}
