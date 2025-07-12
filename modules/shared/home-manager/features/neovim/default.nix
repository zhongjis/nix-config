{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  programs.nvf = {
    enable = true;
    settings = ../../../../../packages/nvf;
  };
}
