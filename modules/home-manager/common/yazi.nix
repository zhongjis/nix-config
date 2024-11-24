{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    yazi.enable =
      lib.mkEnableOption "enables yazi";
  };

  config = lib.mkIf config.thefuck.enable {
    programs.yazi = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
      enableZshIntegration = true;
    };
  };
}
