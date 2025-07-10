{
  pkgs,
  config,
  inputs,
  ...
}: let
in {
  home.packages = [
    inputs.self.packages.${pkgs.system}.neovim
  ];
}
