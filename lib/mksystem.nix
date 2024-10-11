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
  hardwareModule =
    if hardware != ""
    then inputs.nixos-hardware.nixosModules.${hardware}
    else {};
  catppuccinModule =
    if !isDarwin
    then inputs.catppuccin.nixosModules.catppuccin
    else {};
  nhDarwinModule =
    if isDarwin
    then inputs.nh_darwin.nixDarwinModules.prebuiltin
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
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
        };
      }

      hostConfiguration
      hardwareModule
      catppuccinModule
      nhDarwinModule

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
