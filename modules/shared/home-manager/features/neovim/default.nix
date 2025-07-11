{
  pkgs,
  config,
  inputs,
  ...
}: let
  nvfNeovim = inputs.self.packages.${pkgs.system}.neovim;
in {
  home.packages = [
    nvfNeovim
  ];

  home.sessionVariables = {
    EDITOR = "${nvfNeovim}/bin/nvim";
    VISUAL = "${nvfNeovim}/bin/nvim";
  };
}
