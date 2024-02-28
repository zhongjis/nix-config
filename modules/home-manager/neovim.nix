{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    lazygit
    ripgrep
    nodejs_21
    unzip
    cargo
  ];
}
