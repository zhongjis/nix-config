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
      ];
      mkSystem = import ./lib/mksystem.nix {
        inherit overlays nixpkgs inputs;
      };
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ 
            ./hosts/default/configuration.nix
            inputs.home-manager.nixosModules.default
            nixos-hardware.nixosModules.lenovo-thinkpad-t480
          ];
        };
      };

      # darwinConfigurations = {
      #   mac-work = nix-darwin.lib.darwinSystem {
      #     system = "aarch64-darwin";
      #     specialArgs = { inherit inputs; };
      #     modules = [
      #       ./hosts/work-mac/configuration.nix
      #       inputs.home-manager.darwinModules.home-manager
      #     ]; 
      #   };
      # };

      darwinConfigurations.mac-work = 
        mkSystem "mac-work" {
          system  = "aarch64-darwin";
          user    = "zshen";
          darwin  = true;
        };
    };
}
