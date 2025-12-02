{
  description = "Nixos config flake";

  inputs = {
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
  outputs = {
    nixpkgs,
    nvf,
    ...
  } @ inputs: let
    overlays = import ./overlays {inherit inputs;};
    myLib = import ./lib/default.nix {inherit overlays nixpkgs inputs;};
  in
    with myLib; {
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

      packages = forAllSystems (pkgs: {
        # This 'pkgs' argument here is already nixpkgs.legacyPackages.${system}
        neovim =
          (nvf.lib.neovimConfiguration {
            pkgs = pkgs; # Pass the system-specific pkgs
            modules = [./modules/shared/home-manager/features/neovim/nvf];
          }).neovim;
      });

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
}
