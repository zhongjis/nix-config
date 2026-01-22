{
  lib,
  config,
  myLib,
  ...
}: let
  cfg = config.myHomeManager;

  # Scan subdirectories instead of flat structure
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (myLib.filesIn ./features);

  # No more bundle- prefix stripping needed
  bundles =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.bundles.${name}.enable = lib.mkEnableOption "enable ${name} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${name}.enable config);
    })
    (myLib.filesIn ./bundles);

  # NEW: Add services support
  services = let
    serviceFiles =
      if builtins.pathExists ./services
      then myLib.filesIn ./services
      else [];
  in
    if serviceFiles == [] then [] else
      myLib.extendModules
      (name: {
        extraOptions = {
          myHomeManager.services.${name}.enable = lib.mkEnableOption "enable ${name} service";
        };

        configExtension = config: (lib.mkIf cfg.services.${name}.enable config);
      })
      serviceFiles;
in {
  imports =
    []
    ++ features
    ++ bundles
    ++ services;
}
