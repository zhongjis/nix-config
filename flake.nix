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
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      mac-configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          [ pkgs.vim
          ];

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true;  # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
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
        mac-work = nix-darwin.lib.darwinSystem { 
          modules = [
            # ./hosts/work-mac/configuration.nix 
            mac-configuration
          ]; 
        };
      };
    };
}
