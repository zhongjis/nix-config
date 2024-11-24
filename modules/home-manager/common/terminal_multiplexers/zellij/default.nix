{
  pkgs,
  lib,
  config,
  isDarwin,
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

      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };

    xdg.configFile."zellij/config.kdl".source = ./zellij.kdl;
  };
}
