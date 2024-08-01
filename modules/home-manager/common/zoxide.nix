{
  lib,
  config,
  ...
}: {
  options = {
    zoxide.enable =
      lib.mkEnableOption "enables zoxide integration";
  };

  config = lib.mkIf config.zoxide.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
