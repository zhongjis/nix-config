{
  description = "NodeJS dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          shell = "/bin/zsh";
          shellHook = ''
            echo "[[nodejs_22]] shell activated!!!"
          '';
          packages = with pkgs; [
            nodejs_22
            pnpm
          ];
        };
      }
    );
}
