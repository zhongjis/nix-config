# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{
  nixpkgs,
  overlays,
  inputs,
}: systemName: {
  system,
  user,
  hardware ? "",
  darwin ? false,
}: let
  isDarwin = darwin;
  hostConfiguration = ../hosts/${systemName}/configuration.nix;
  systemFunc =
    if isDarwin
    then inputs.nix-darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  hmModule =
    if isDarwin
    then inputs.home-manager.darwinModules.home-manager
    else inputs.home-manager.nixosModules.default;
  hardwareModule =
    if hardware != ""
    then inputs.nixos-hardware.nixosModules.${hardware}
    else {};
  catppuccinModule =
    if !isDarwin
    then inputs.catppuccin.nixosModules.catppuccin
    else {};
in
  systemFunc {
    system = system;
    specialArgs = {inherit inputs;};

    modules = [
      {
        nixpkgs = {
          overlays = [
            inputs.nixpkgs-terraform.overlays.default
            overlays.modifications
            overlays.unstable-packages
          ];
          config.allowUnfree = true;
          config.allowUnfreePredicate = _: true;
        };
      }

      hostConfiguration
      hmModule
      hardwareModule
      catppuccinModule

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs isDarwin systemName;};
          users.${user}.imports = [
            ../hosts/${systemName}/home.nix
            inputs.catppuccin.homeManagerModules.catppuccin
          ];
        };
      }

      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = systemName;
          currentSystemUser = user;
          inputs = inputs;
          isDarwin = darwin;
        };
      }
    ];
  }
