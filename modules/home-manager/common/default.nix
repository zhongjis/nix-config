{ lib, config, ... }:

{
  imports = [
    ./alacritty
    ./git.nix
    ./k9s.nix
    ./zsh.nix
    ./neovim
    ./tmux
  ];

  alacritty.enable = lib.mkDefault true;
  zsh.enable = lib.mkDefault true;
  neovim.enable = lib.mkDefault true;
  tmux.enable = lib.mkDefault true;

  git.enable = lib.mkDefault false;
  k9s.enable = lib.mkDefault false;
}
