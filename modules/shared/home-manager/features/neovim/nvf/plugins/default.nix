{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./lsp
    ./cmp.nix
    ./gitsigns.nix
    ./mini.nix
    ./oil.nix
    ./telescope.nix
    ./todo-comments.nix
    ./toggleterm.nix
    ./trouble.nix
    ./visual.nix
    ./whichkey.nix
  ];
}
