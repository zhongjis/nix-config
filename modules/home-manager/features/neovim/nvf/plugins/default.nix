{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./lsp
    ./cmp.nix
    ./copilot.nix
    ./gitsigns.nix
    ./mini.nix
    ./oil.nix
    ./telescope.nix
    ./todo-comments.nix
    ./toggleterm.nix
    ./visual.nix
    ./whichkey.nix
  ];
}
