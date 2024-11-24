{
  lib,
  config,
  ...
}: {
  options = {
    fastfetch.enable =
      lib.mkEnableOption "enable fastfetch";
  };

  config = lib.mkIf config.fastfetch.enable {
    programs.fastfetch = {
      enable = true;
    };
  };
}
