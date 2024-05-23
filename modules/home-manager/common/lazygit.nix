{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    lazygit.enable =
      lib.mkEnableOption "enables lazygit";
  };

  config = lib.mkIf config.lazygit.enable {
    xdg.enable = true;
    programs.lazygit = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };
  };
}
