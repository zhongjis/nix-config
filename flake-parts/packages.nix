{inputs, ...}: {
  perSystem = {
    config,
    pkgs,
    lib,
    system,
    ...
  }: {
    packages = let
      inherit (lib) optionalAttrs;
    in
      {
        neovim =
          (inputs.nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [../modules/home-manager/features/neovim/nvf];
          }).neovim;
      }
      // {
        oh-my-codex = inputs.llm-agents.packages.${system}.oh-my-codex;
        opencode-morph-fast-apply = import ../packages/opencode-morph-fast-apply.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        openkanban = import ../packages/openkanban.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      }
      // {
        sentrux = import ../packages/sentrux.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      }
      // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        helium = import ../packages/helium.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        fincept-terminal = import ../packages/fincept-terminal.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      };
  };
}
