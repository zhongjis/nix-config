{
  inputs,
  lib,
  ...
}: let
  nixConfig = import ./nix-settings.nix {inherit lib;};
in {
  imports = [
    ./cachix.nix
    ./packages
  ];

  # set global nix path
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # Shared Nix daemon settings for NixOS and nix-darwin evaluations.
  nix.settings =
    nixConfig.settings
    // {
      substituters = lib.mkForce nixConfig.settings.substituters;
      trusted-public-keys = lib.mkForce nixConfig.settings.trusted-public-keys;
    };

  # nix.package = pkgs.nix; # NOTE: managed by determinate nix
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.optimise.automatic = lib.mkDefault true;
}
