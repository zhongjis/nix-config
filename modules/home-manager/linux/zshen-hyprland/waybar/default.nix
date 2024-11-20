{
  pkgs,
  lib,
  config,
  ...
}: let
  waybarConfig = (import ./config.nix).fileText;
  waybarModules = (import ./modules.nix {inherit pkgs;}).fileText;
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

    xdg.configFile."waybar/config".text = waybarConfig;
    xdg.configFile."waybar/modules".text = waybarModules;

    home.packages = with pkgs.unstable; [
      jq
      blueman
      playerctl
      cava
      (writeScriptBin "restart-waybar" ''
        ${builtins.readFile ./restart-waybar.sh}
      '')
    ];
  };
}
