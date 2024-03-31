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
    ${builtins.readFile ./rofi-toggle.sh}
  '')
  ];
}
