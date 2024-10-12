# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{
  nixpkgs,
  overlays,
  inputs,
}: systemName: {
  system,
  darwin ? false,
}: let
  isDarwin = darwin;
  hostConfiguration = ../hosts/${systemName}/home.nix;
  systemFunc = inputs.home-manager.lib.homeManagerConfiguration;
  catppuccinModule = inputs.catppuccin.homeManagerModules.catppuccin;
in
  systemFunc {
    system = system;
    extraSpecialArgs = {inherit inputs;};

    modules = [
      {
        nixpkgs = {
          overlays = [
            inputs.nixpkgs-terraform.overlays.default
            overlays.modifications
            overlays.unstable-packages
          ];
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
        };
      }

      hostConfiguration
      catppuccinModule

      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = systemName;
          inputs = inputs;
          isDarwin = darwin;
        };
      }
    ];
  }
