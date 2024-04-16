# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{ nixpkgs, overlays, inputs }:

name:
{ system
, user
, hardware ? ""
, isDarwin ? false
}:

let
  hostConfiguration = ../hosts/${name}/configuration.nix;
  systemFunc =
    if isDarwin then
      inputs.nix-darwin.lib.darwinSystem
    else
      nixpkgs.lib.nixosSystem;
  hmModule =
    if isDarwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.default;
  hardwareModule =
    if hardware != "" then
      inputs.nixos-hardware.nixosModules.${hardware}
    else
      { };
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
    hmModule
    hardwareModule

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs isDarwin; };
        users.${user} = import ../hosts/${name}/home.nix;
      };
    }

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
