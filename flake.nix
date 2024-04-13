{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    hyprland.url = "github:hyprwm/Hyprland";
    xremap-flake.url = "github:xremap/nix-flake";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, nix-darwin, nixos-hardware, ... }@inputs:
    let
      overlays = [
        inputs.neovim-nightly-overlay.overlay
        inputs.nixpkgs-terraform.overlays.default
      ];
      mkSystem = import ./lib/mksystem.nix {
        inherit overlays nixpkgs inputs;
      };
    in
    {
      nixosConfigurations.thinkpad-t480 =
        mkSystem "thinkpad-t480" {
          system   = "x86_64-linux";
          user     = "zshen";
          hardware = "lenovo-thinkpad-t480";
        };

      darwinConfigurations.mac-m1-max = 
        mkSystem "mac-m1-max" {
          system  = "aarch64-darwin";
          user    = "zshen";
          darwin  = true;
        };
    };
}
