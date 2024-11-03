{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    zellij.enable =
      lib.mkEnableOption "enables zellij";
  };

  config = lib.mkIf config.zellij.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
