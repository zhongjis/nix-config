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
  services =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.services.${name}.enable = lib.mkEnableOption "enable ${name} service";
      };

      configExtension = config: (lib.mkIf cfg.services.${name}.enable config);
    })
    (myLib.filesIn ./services);
in {
  imports =
    []
    ++ features
    ++ bundles
    ++ services;

  xdg.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      experimental-features = "nix-command flakes";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
