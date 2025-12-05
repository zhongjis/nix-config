{
  description = "Nixos config flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nix-config-private = {
      url = "git+ssh://git@github.com/zhongjis/nix-config-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    # darwin
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## nix-flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    ## nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    aerospace-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    # programs
    xremap-flake.url = "github:xremap/nix-flake";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    stylix.url = "github:danth/stylix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nvf.url = "github:notashelf/nvf/v0.8";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    ## hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hy3 = {
      # WAITFOR: https://github.com/outfoxxed/hy3/issues/230
      # url = "github:outfoxxed/hy3?ref=hl0.50.0";
      url = "github:outfoxxed/hy3?ref=cdcbc57f7e4925bbf8d1589bbb454e660df2b88e";
      inputs.hyprland.follows = "hyprland";
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };

    ## framework laptop
    fw-fanctrl = {
      url = "github:TamtamHero/fw-fanctrl/packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/niksingh710/minimal-tmux-status/
    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    nvf,
    ...
  }: let
    overlays = import ./overlays {inherit inputs;};
    myLib = import ./lib/default.nix {inherit overlays nixpkgs inputs;};
    
    # Common overlays list
    commonOverlays = [
      inputs.nixpkgs-terraform.overlays.default
      overlays.modifications
      overlays.stable-packages
    ];
    
    # Common nixpkgs config
    commonNixpkgsConfig = {
      allowUnfree = true;
      permittedInsecurePackages = [];
      allowUnfreePredicate = _: true;
    };
    
    # Common module args for NixOS/Darwin
    mkModuleArgs = system: hostName: user: darwin: {
      currentSystem = system;
      currentSystemName = hostName;
      currentSystemUser = user;
      inputs = inputs;
      isDarwin = darwin;
    };
    
    # Build outputs using flake-parts
    outputs = flake-parts.lib.mkFlake { inherit inputs; } {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      
      perSystem = {system, pkgs, ...}: {
        packages = {
          neovim = (nvf.lib.neovimConfiguration {
            pkgs = pkgs;
            modules = [./modules/shared/home-manager/features/neovim/nvf];
          }).neovim;
        };
      };
      
      flake = {
        nixosConfigurations = {
          framework-16 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs myLib;
            };
            modules = [
              ./hosts/framework-16/configuration.nix
              inputs.nixos-hardware.nixosModules.framework-16-7040-amd
              inputs.chaotic.nixosModules.default
              inputs.determinate.nixosModules.default
              inputs.sops-nix.nixosModules.sops
              {
                nixpkgs.overlays = commonOverlays;
                nixpkgs.config = commonNixpkgsConfig;
              }
              {
                config._module.args = mkModuleArgs "x86_64-linux" "framework-16" "zshen" false;
              }
            ];
          };
        };

        darwinConfigurations = {
          Zs-MacBook-Pro = inputs.nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = {
              inherit inputs myLib;
            };
            modules = [
              ./hosts/mac-m1-max/configuration.nix
              inputs.sops-nix.darwinModules.sops
              {
                nixpkgs.overlays = commonOverlays;
                nixpkgs.config = commonNixpkgsConfig;
              }
              {
                config._module.args = mkModuleArgs "aarch64-darwin" "mac-m1-max" "zshen" true;
              }
            ];
          };
        };

        homeConfigurations = {
          "zshen@Zs-MacBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "aarch64-darwin";
              overlays = commonOverlays;
            };
            extraSpecialArgs = {
              inherit inputs myLib;
              currentSystem = "aarch64-darwin";
              currentSystemName = "mac-m1-max";
              isDarwin = true;
            };
            modules = [
              ./hosts/mac-m1-max/home.nix
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          };
          "zshen@framework-16" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = commonOverlays;
            };
            extraSpecialArgs = {
              inherit inputs myLib;
              currentSystem = "x86_64-linux";
              currentSystemName = "framework-16";
              isDarwin = false;
            };
            modules = [
              ./hosts/framework-16/home.nix
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          };
        };

        templates = {
          java8 = {
            path = ./templates/java8;
            description = "nix flake new -t github:zhongjis/nix-config#java8 .";
          };
          nodejs22 = {
            path = ./templates/nodejs22;
            description = "nix flake new -t github:zhongjis/nix-config#nodejs22 .";
          };
        };

        nixDarwinModules.default = ./modules/darwin;
        homeManagerModules.default = ./modules/shared/home-manager;
        homeManagerModules.linux = ./modules/nixos/home-manager;
        homeManagerModules.darwin = ./modules/darwin/home-manager;
      };
    };
  in outputs;
}
