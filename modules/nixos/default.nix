{
  pkgs,
  config,
  lib,
  inputs,
  outputs,
  myLib,
  ...
}: let
  cfg = config.myNixOS;

  # Taking all modules in ./features and adding enables to them
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myNixOS.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (myLib.filesIn ./features);
in {
  imports =
    features;
  # ++ bundles
  # ++ services;

  config = {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    programs.nix-ld.enable = true;
    nixpkgs.config.allowUnfree = true;
  };
}
