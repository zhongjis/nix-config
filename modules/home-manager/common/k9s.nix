{
  lib,
  config,
  ...
}: {
  options = {
    k9s.enable =
      lib.mkEnableOption "enables k9s";
  };

  config = lib.mkIf config.k9s.enable {
    programs.k9s = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      settings = {
        k9s = {
          refreshRate = 2;
        };
      };
    };
  };
}
