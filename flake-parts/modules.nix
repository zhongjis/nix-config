{ inputs, lib, ... }:
let
  tree = inputs.import-tree.withLib lib;

  # Helper to discover and convert to attrset
  discoverModules = dir:
    let
      files = (tree.addPath dir).files;
    in
    lib.listToAttrs (
      map
        (path: {
          name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
          value = path;
        })
        files
    );
in
{
  flake = {
    # NixOS modules - auto-discovered
    nixosModules =
      { default = ../modules/nixos; }
      // discoverModules ../modules/nixos/features
      // discoverModules ../modules/nixos/bundles
      // discoverModules ../modules/nixos/services;

    # Darwin modules - auto-discovered
    darwinModules =
      { default = ../modules/darwin; }
      // discoverModules ../modules/darwin/features
      // discoverModules ../modules/darwin/bundles;

    # Home Manager modules
    homeManagerModules = {
      default = ../modules/home-manager;
    };
  };
}
