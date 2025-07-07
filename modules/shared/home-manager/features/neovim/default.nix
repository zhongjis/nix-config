{
  pkgs,
  inputs,
  ...
}: let
  configModule = {
    # Add any custom options (and do feel free to upstream them!)
    # options = { ... };

    config.vim = {
      # theme.enable = true;
      # and more options as you see fit...
    };
  };

  customNeovim = inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [configModule];
  };
in {
  home.packages = [customNeovim.neovim];
}
