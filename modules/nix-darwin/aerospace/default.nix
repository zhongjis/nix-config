{
  lib,
  config,
  pkgs,
  ...
}: let
in {
  options = {
    aerospace.enable =
      lib.mkEnableOption "enables aerospace";
  };

  config = lib.mkIf config.aerospace.enable {
    homebrew.casks = [
      "nikitabobko/tap/aerospace"
    ];

    xdg.configFile.aerospace.source = ./aerospace.toml;
  };
}
