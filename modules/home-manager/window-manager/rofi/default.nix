{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.alacritty}/bin/alacritty";
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "rofi-toggle" ''
      ${./rofi-toggle.sh}/bin/bash ${./rofi-toggle.sh} 
    '')
  ];
}
