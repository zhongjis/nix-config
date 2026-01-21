{
  lib,
  config,
  myLib,
  ...
}: let
  cfg = config.myHomeManager;

  allFiles = myLib.filesIn ./.;

  # Filter out default.nix to avoid infinite recursion
  nonDefaultFiles = builtins.filter
    (path: (baseNameOf path) != "default.nix")
    allFiles;

  # Filter files that don't start with bundle-
  featureFiles = builtins.filter
    (path: !(lib.hasPrefix "bundle-" (myLib.fileNameOf path)))
    nonDefaultFiles;

  # Filter files that start with bundle- and strip the prefix
  bundleFiles = builtins.filter
    (path: lib.hasPrefix "bundle-" (myLib.fileNameOf path))
    nonDefaultFiles;

  # Taking all modules except bundles and adding enables to them
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    featureFiles;

  # Taking all bundle-*.nix modules and adding bundle.enables to them
  # Strip "bundle-" prefix from the name for the option path
  bundles =
    myLib.extendModules
    (name: let
      bundleName = lib.removePrefix "bundle-" name;
    in {
      extraOptions = {
        myHomeManager.bundles.${bundleName}.enable = lib.mkEnableOption "enable ${bundleName} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${bundleName}.enable config);
    })
    bundleFiles;
in {
  imports =
    []
    ++ features
    ++ bundles;
}
