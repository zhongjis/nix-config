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
        agent-of-empires = import ../packages/agent-of-empires.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        opencode-morph-fast-apply = import ../packages/opencode-morph-fast-apply.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        openkanban = import ../packages/openkanban.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      }
      // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        helium = import ../packages/helium.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        agent-browser = import ../packages/agent-browser.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      };
  };
}
