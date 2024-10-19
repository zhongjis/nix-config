{
  pkgs,
  config,
  lib,
  currentSystemName,
  ...
}: let
  fontSize =
    if currentSystemName == "mac-m1-max"
    then 18
    else 13;
in {
  options = {
    kitty.enable =
      lib.mkEnableOption "enables kitty";
  };

  config = lib.mkIf config.kitty.enable {
    programs.kitty = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      shellIntegration.enableZshIntegration = true;

      settings = {
        
      };
    };
  };
}
