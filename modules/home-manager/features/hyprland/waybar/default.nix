{pkgs, ...}: let
  waybarConfig = (import ./config.nix).fileText;
  waybarModules = (import ./modules.nix {inherit pkgs;}).fileText;
in {
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
    pamixer
    gnome-system-monitor
    playerctl
    cava
    (writeScriptBin "restart-waybar" ''
      ${builtins.readFile ./restart-waybar.sh}
    '')
  ];
}
