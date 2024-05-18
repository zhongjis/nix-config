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
    # https://github.com/catppuccin/nix/tree/main/modules/home-manager
    catppuccin.url = "github:catppuccin/nix";

    # neovim
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    trouble-v3 = {
      url = "github:folke/trouble.nvim/dev";
      flake = false;
    };
    solarized-osaka-nvim = {
      url = "github:craftzdog/solarized-osaka.nvim";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nix-darwin, nixos-hardware, ... }@inputs:
    let
      overlays = [
        inputs.neovim-nightly-overlay.overlay
        inputs.nixpkgs-terraform.overlays.default
        (final: prev: rec {
          jdk = prev."jdk${toString 17}";
          maven = prev.maven.override { inherit jdk; };
        })
        (final: prev: {
          vimPlugins = prev.vimPlugins // {
            trouble-nvim = prev.vimUtils.buildVimPlugin
              {
                name = "trouble.nvim";
                src = inputs.trouble-v3;
              };
            solarized-osaka-nvim = prev.vimUtils.buildVimPlugin
              {
                name = "solarized-osaka.nvim";
                src = inputs.solarized-osaka-nvim;
              };
          };
        })
      ];
      mkSystem = import ./lib/mksystem.nix {
        inherit overlays nixpkgs inputs;
      };
    in
    {
      nixosConfigurations.thinkpad-t480 =
        mkSystem "thinkpad-t480" {
          system = "x86_64-linux";
          user = "zshen";
          hardware = "lenovo-thinkpad-t480";
        };

      darwinConfigurations.mac-m1-max =
        mkSystem "mac-m1-max" {
          system = "aarch64-darwin";
          user = "zshen";
          darwin = true;
        };
    };
}
