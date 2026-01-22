{ inputs, lib, ... }:
let
  overlays = import ../overlays { inherit inputs; };
  myLib = import ../lib/default.nix {
    inherit overlays;
    nixpkgs = inputs.nixpkgs;
    inherit inputs;
  };
in
{
  flake = with myLib; {
    nixosConfigurations = {
      framework-16 = mkSystem "framework-16" {
        system = "x86_64-linux";
        hardware = "framework-16-7040-amd";
        user = "zshen";
      };
    };

    darwinConfigurations = {
      Zs-MacBook-Pro = mkSystem "mac-m1-max" {
        system = "aarch64-darwin";
        user = "zshen";
        darwin = true;
      };
    };

    homeConfigurations = {
      "zshen@Zs-MacBook-Pro" = mkHome "mac-m1-max" {
        system = "aarch64-darwin";
        darwin = true;
      };
      "zshen@thinkpad-t480" = mkHome "thinkpad-t480" {
        system = "x86_64-linux";
      };
      "zshen@framework-16" = mkHome "framework-16" {
        system = "x86_64-linux";
      };
    };
  };
}
