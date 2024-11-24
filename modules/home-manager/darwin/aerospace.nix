{
  lib,
  config,
  ...
}: {
  options = {
    aerospace.enable =
      lib.mkEnableOption "enable aerospace packages";
  };

  config = lib.mkIf config.aerospace.enable {
    xdg.configFile."aerospace/aerospace.toml".source = ../../nix-darwin/aerospace/aerospace.toml;
  };
}
