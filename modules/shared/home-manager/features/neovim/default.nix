{
  pkgs,
  inputs,
  ...
}: let
  configModule = {
    # Add any custom options (and do feel free to upstream them!)
    # options = { ... };
    config = ./nvf-configuration.nix;
  };

  customNeovim = inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [configModule];
  };
in {
  home.packages = [customNeovim.neovim];
}
