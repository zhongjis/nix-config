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
  homeConfiguration = ../hosts/${systemName}/home.nix;
  pkgsWithOverlay = import nixpkgs {
    inherit system;
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
in
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = pkgsWithOverlay;
    extraSpecialArgs = {inherit inputs;};

    modules = [
      homeConfiguration
      inputs.catppuccin.homeManagerModules.catppuccin

      {
        config._module.args = {
          system = system;
          systemName = systemName;
          inputs = inputs;
          isDarwin = darwin;
        };
      }
    ];
  }
