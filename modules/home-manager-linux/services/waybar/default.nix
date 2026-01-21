{pkgs, ...}: {
  imports = [
    ./modules.nix
    ./config.nix
    ./style.nix
  ];
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    });
  };

  home.packages = with pkgs; [
    jq
    pamixer
    playerctl
    (writeScriptBin "restart-waybar" ''
      ${builtins.readFile ./restart-waybar.sh}
    '')
  ];
}
