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

      settings = {
        copy_command =
          if isDarwin
          then "xclip -selection clipboard"
          else "wl-copy";
      };
    };
  };
}
