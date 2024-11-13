{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    xremap-flake.url = "github:xremap/nix-flake";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    # https://github.com/catppuccin/nix/tree/main/modules/home-manager
    catppuccin.url = "github:catppuccin/nix";

    # neovim
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    trouble-nvim = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
    oil-nvim = {
      url = "github:stevearc/oil.nvim";
      flake = false;
    };

    nh_darwin.url = "github:ToyVo/nh_darwin";

    # secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {nixpkgs, ...} @ inputs: let
    overlays = import ./overlays {inherit inputs;};

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };

    mkHomeManager = import ./lib/mkhomemanager.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.thinkpad-t480 = mkSystem "thinkpad-t480" {
      system = "x86_64-linux";
      user = "zshen";
      hardware = "lenovo-thinkpad-t480";
    };

    nixosConfigurations.razer-14 = mkSystem "razer-14" {
      system = "x86_64-linux";
      user = "zshen";
    };

    darwinConfigurations.mac-m1-max = mkSystem "mac-m1-max" {
      system = "aarch64-darwin";
      user = "zshen";
      darwin = true;
    };

    homeConfigurations."zshen-mac" = mkHomeManager "mac-m1-max" {
      system = "aarch64-darwin";
      darwin = true;
    };

    homeConfigurations."zshen-linux" = mkHomeManager "thinkpad-t480" {
      system = "x86_64-linux";
      darwin = false;
    };
  };
}
