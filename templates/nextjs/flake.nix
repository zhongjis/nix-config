{
  description = "NextJS 16 dev env for t3 stack";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    systems.url = "github:nix-systems/default";
    nix-config = {
      url = "github:zhongjis/nix-config";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    nix-config,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        agent-browser = nix-config.packages.${system}.agent-browser;

        cleanupScript =
          pkgs.writeShellScript "cleanup-stale-agent-browser"
          (builtins.readFile ./nix/cleanup-stale-agent-browser.sh);

        shellHook =
          builtins.replaceStrings
          ["@opensslDev@" "@prismaEngines@" "@cleanupScript@" "@agentBrowserPath@"]
          ["${pkgs.openssl.dev}" "${pkgs.prisma-engines}" "${cleanupScript}" "${agent-browser}"]
          (builtins.readFile ./nix/shell-hook.sh);
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            prisma-engines
            prisma
          ];
          packages = with pkgs; [
            nodejs_22
            pnpm
            openssl
            sqlite
            agent-browser
          ];
          shell = "/bin/zsh";
          inherit shellHook;
        };
      }
    );
}
