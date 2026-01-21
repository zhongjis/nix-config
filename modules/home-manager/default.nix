{
  lib,
  config,
  myLib,
  ...
}: let
  cfg = config.myHomeManager;

  # Taking all modules in current directory and adding enables to them
  # This handles both simple .nix files and directories with default.nix
  # Excludes bundle-*.nix files which are handled separately
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (builtins.filter
      (path: !(lib.hasPrefix "bundle-" (baseNameOf path)))
      (myLib.filesIn ./.));

  # Taking all bundle-*.nix modules and adding bundle.enables to them
  bundles =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.bundles.${name}.enable = lib.mkEnableOption "enable ${name} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${name}.enable config);
    })
    (builtins.filter
      (path: lib.hasPrefix "bundle-" (baseNameOf path))
      (myLib.filesIn ./.));
in {
  imports =
    []
    ++ features
    ++ bundles;

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
