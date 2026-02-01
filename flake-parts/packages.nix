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
