{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    thefuck.enable =
      lib.mkEnableOption "enables thefuck";
  };

  config = lib.mkIf config.thefuck.enable {
    programs.thefuck = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
