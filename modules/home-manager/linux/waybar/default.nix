{
  pkgs,
  lib,
  config,
  ...
}: let
  config = (import ./config.nix).value;
  modules = (import ./modules.nix).value;
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
    xdg.configFile."waybar/modules".text = modules;

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
