{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    # darwin
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
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
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    ghostty.url = "github:ghostty-org/ghostty";

    ## hyprland
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprswitch.url = "github:h3rmt/hyprswitch/release";

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
  outputs = {nixpkgs, ...} @ inputs: let
    overlays = import ./overlays {inherit inputs;};
    myLib = import ./lib/default.nix {inherit overlays nixpkgs inputs;};
  in
    with myLib; {
      nixosConfigurations = {
        thinkpad-t480 = mkSystem "thinkpad-t480" {
          system = "x86_64-linux";
          hardware = "lenovo-thinkpad-t480";
          user = "zshen";
        };
        framework-16 = mkSystem "framework-16" {
          system = "x86_64-linux";
          hardware = "framework-16-7040-amd";
          user = "zshen";
        };
      };

      darwinConfigurations = {
        mac-m1-max = mkSystem "mac-m1-max" {
          system = "aarch64-darwin";
          user = "zshen";
          darwin = true;
        };
      };

      homeConfigurations = {
        "zshen@mac-m1-max" = mkHome "mac-m1-max" {
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

      nixosModules.default = ./modules/nixos;
      nixDarwinModules.default = ./modules/darwin;
      homeManagerModules.default = ./modules/home-manager;
      homeManagerModules.linux = ./modules/home-manager-linux;
      homeManagerModules.darwin = ./modules/home-manager-darwin;
    };
}
