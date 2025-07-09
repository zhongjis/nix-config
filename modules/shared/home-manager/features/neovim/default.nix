{
  pkgs,
  inputs,
  ...
}: let
  configModule = import ./nvf-configuration.nix;

  customNeovim = inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [configModule];
  };
in {
  home.packages = [customNeovim.neovim];
}
