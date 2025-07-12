{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./cmp.nix
    ./formatter.nix
    ./lint.nix
    ./lsp.nix
    ./telescope.nix
    ./toggleterm.nix
  ];
}
