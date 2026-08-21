{
  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="];
  };

  description = "NodeJS dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    llm-agents.url = "github:numtide/llm-agents.nix";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    llm-agents,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        agent-browser = llm-agents.packages.${system}.agent-browser;
      in {
        devShells.default = pkgs.mkShell {
          shell = "/bin/zsh";
          shellHook = ''
            echo "[[nodejs_26]] shell activated!!!"
          '';
          packages = with pkgs; [
            nodejs_26
            pnpm
            agent-browser
          ];
        };
      }
    );
}
