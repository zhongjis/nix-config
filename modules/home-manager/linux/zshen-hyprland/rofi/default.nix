{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    rofi.enable =
      lib.mkEnableOption "enables rofi";
  };

  config = lib.mkIf config.rofi.enable {
    programs.rofi = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      package = pkgs.rofi-wayland;
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    home.packages = with pkgs; [
      (writeScriptBin "rofi-toggle" ''
        ${builtins.readFile ./rofi-toggle.sh}
      '')
    ];
  };
}
