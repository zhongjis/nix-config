{
  pkgs,
  inputs,
  config,
  ...
}: let
  configModule = import ./nvf-configuration.nix;

  customNeovim = inputs.nvf.lib.neovimConfiguration {
    inherit pkgs config;
    modules = [ configModule ];
  };
in {
  home.packages = [customNeovim.neovim];
}
