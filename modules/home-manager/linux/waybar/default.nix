{
  pkgs,
  lib,
  config,
  ...
}: let
  cava-sh = pkgs.writeShellScript ./scripts/WaybarCava.sh;
  config = (import ./config.nix).value;
in {
  options = {
    waybar.enable =
      lib.mkEnableOption "enables waybar";
  };

  config = lib.mkIf config.waybar.enable {
    programs.waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      });
      style = ''
        ${builtins.readFile ./style.css}
      '';
    };

    xdg.configFile."waybar/config".text = config;
    xdg.configFile."waybar/modules".source = ./modules;

    home.packages = with pkgs; [
      playerctl
      cava
      swaynotificationcenter
      (writeScriptBin "restart-waybar" ''
        ${builtins.readFile ./restart-waybar.sh}
      '')
    ];
  };
}
