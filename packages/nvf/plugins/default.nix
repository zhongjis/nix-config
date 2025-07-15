{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./lsp
    ./cmp.nix
    ./oil.nix
    ./telescope.nix
    ./toggleterm.nix
    ./trouble.nix
    ./visual.nix
    ./whichkey.nix
  ];
}
