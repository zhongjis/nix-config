{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

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
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake.url = "github:xremap/nix-flake";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    stylix.url = "github:danth/stylix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nvf.url = "github:notashelf/nvf";
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
      url = "github:outfoxxed/hy3";
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

  outputs = inputs:
    let
      overlays = import ./overlays { inherit inputs; };
      myLib = import ./lib/default.nix { inherit inputs overlays; nixpkgs = inputs.nixpkgs; };
    in
    (inputs.flake-parts.lib.mkFlake { inherit inputs; }) {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./modules/flake/default.nix
      ];

      perSystem = { pkgs, lib, system, ... }: {
        packages = {
          neovim =
            (inputs.nvf.lib.neovimConfiguration {
              pkgs = pkgs;
              modules = [./modules/shared/home-manager/features/neovim/nvf];
            }).neovim;
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          helium = import ./packages/helium.nix {
            inherit pkgs lib;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            name = "nix-config-dev";
            packages = with pkgs; [
              nix-tree
              nix-diff
              nil
              statix
              deadnix
            ];
          };
        };

        formatter = pkgs.nixfmt;

        checks = {
          # Can add validation checks here
        };
      };

      flake = {
        nixosConfigurations = {
          framework-16 = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs myLib; };
            modules = [
              ./hosts/framework-16/configuration.nix
              inputs.determinate.nixosModules.default
              inputs.sops-nix.nixosModules.sops

              # Apply overlays
              {
                nixpkgs.overlays = [
                  overlays.modifications
                  overlays.stable-packages
                ];
              }
            ];
          };
        };

        darwinConfigurations = {
          "Zs-MacBook-Pro" = inputs.nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit inputs myLib; };
            modules = [
              ./hosts/mac-m1-max/configuration.nix
              inputs.sops-nix.darwinModules.sops
            ];
          };
        };

        homeConfigurations = {
          "zshen@framework-16" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = {
              inherit inputs myLib;
              currentSystem = "x86_64-linux";
              currentSystemName = "framework-16";
            };
            modules = [
              ./hosts/framework-16/home.nix
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          };
          "zshen@Zs-MacBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
            extraSpecialArgs = {
              inherit inputs myLib;
              currentSystem = "aarch64-darwin";
              currentSystemName = "mac-m1-max";
            };
            modules = [
              ./hosts/mac-m1-max/home.nix
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
}
