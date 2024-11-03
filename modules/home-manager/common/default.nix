{
  lib,
  config,
  ...
}: {
  imports = [
    ./git.nix
    ./k9s.nix
    ./fzf.nix
    ./zsh
    ./neovim
    ./thefuck.nix
    ./zoxide.nix
    ./lazygit.nix
    ./fastfetch.nix
    ./sops.nix

    ./terminal_emulators
    ./terminal_multiplexers
  ];

  options = {
    common.enable =
      lib.mkEnableOption "enable common packages";
  };

  config = lib.mkIf config.common.enable {
    zsh.enable = lib.mkDefault true;
    fzf.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    lazygit.enable = lib.mkDefault true;
    fastfetch.enable = lib.mkDefault true;
    thefuck.enable = lib.mkDefault true;
    zoxide.enable = lib.mkDefault true;
    git.enable = lib.mkDefault false;
    k9s.enable = lib.mkDefault false;

    terminal_emulator.enable = lib.mkDefault true;
    terminal_multiplexer.enable = lib.mkDefault true;
  };
}
