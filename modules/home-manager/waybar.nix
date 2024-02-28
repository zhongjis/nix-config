{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    # TODO: add this for the latest waybar
    # package = ""
    settings = {
    };
  };

  home.packages = with pkgs; [
    rofi
    killall
  ];
}
