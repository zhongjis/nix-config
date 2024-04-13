# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
  darwin ? false,
}:

let
  hostConfiguration = ../hosts/${name}/configuration.nix;
  systemFunc = if darwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager-module = if darwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.default;
in 
systemFunc {
  system = system;
  specialArgs = { inherit inputs; };

  modules = [
    { 
      nixpkgs = {
        overlays = overlays; 
        config.allowUnfree = true;
      };
    }

    hostConfiguration 
    home-manager-module

    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        inputs = inputs;
      };
    }
  ];
}
