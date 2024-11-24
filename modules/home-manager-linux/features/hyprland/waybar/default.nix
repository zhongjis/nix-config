{
  pkgs,
  isDarwin,
  ...
}: let
  waybarConfig = (import ./config.nix).fileText;
  waybarModules = (import ./modules.nix {inherit pkgs;}).fileText;
in {
  programs.waybar = {
    enable =
      if isDarwin
      then false
      else true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    });
    style = ''
      ${builtins.readFile ./style.css}
    '';
  };

  xdg.configFile."waybar/config".text = waybarConfig;
  xdg.configFile."waybar/modules".text = waybarModules;

  home.packages = with pkgs; [
    jq
    pamixer
    gnome-system-monitor
    playerctl
    (writeScriptBin "restart-waybar" ''
      ${builtins.readFile ./restart-waybar.sh}
    '')
  ];
}
