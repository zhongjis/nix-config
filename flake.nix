{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:LnL7/nix-darwin"; 
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs"; 

    hyprland.url = "github:hyprwm/Hyprland";
    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs = { self, nixpkgs, nix-darwin, nixos-hardware, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [ 
            ./hosts/default/configuration.nix
            inputs.home-manager.nixosModules.default
	        nixos-hardware.nixosModules.lenovo-thinkpad-t480
          ];
        };
      };

      darwinConfigurations = {
        "Zhongjies-MacBook-Pro-2" = nix-darwin.lib.darwinSystem { 
          modules = [
            ./hosts/work-mac/configuration.nix 
            inputs.home-manager.nixosModules.default
          ]; 
        };
      };
    };
}
