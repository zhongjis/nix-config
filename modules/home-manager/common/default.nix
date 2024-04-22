{ lib, config, ... }:

{
  imports = [
    ./alacritty.nix
    ./git.nix
    ./k9s.nix
    ./fzf.nix
    ./zsh
    ./neovim
    ./tmux
    ./lazygit.nix
  ];

  options = {
    common.enable =
      lib.mkEnableOption "enable common packages";
  };

  config = lib.mkIf config.common.enable {
    alacritty.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
    fzf.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    tmux.enable = lib.mkDefault true;
    lazygit.enable = lib.mkDefault true;

    git.enable = lib.mkDefault false;
    k9s.enable = lib.mkDefault false;
  };
}
