{
  lib,
  config,
  ...
}: {
  options = {
    sketchybar.enable =
      lib.mkEnableOption "enables sketchybar";
  };

  config = lib.mkIf config.sketchybar.enable {
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    services.sketchybar = {
      enable = true;
    };
  };
}
