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
    ./oil.nix
    ./telescope.nix
    ./toggleterm.nix
    ./trouble.nix
    ./whichkey.nix
  ];
}
