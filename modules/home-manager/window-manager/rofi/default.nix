{ pkgs, lib, config, ... }:

{
  options = {
    rofi.enable =
      lib.mkEnableOption "enables rofi";
  };

  config = lib.mkIf config.rofi.enable {
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
  };
}
