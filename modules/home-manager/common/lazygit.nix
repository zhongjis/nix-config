{
  lib,
  config,
  pkgs,
  ...
}: {
  options = {
    lazygit.enable =
      lib.mkEnableOption "enables lazygit";
  };

  config = lib.mkIf config.lazygit.enable {
    programs.lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };
  };
}
