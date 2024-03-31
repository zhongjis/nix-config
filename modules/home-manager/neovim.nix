{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
        lazygit
        ripgrep
        nodejs_21
        unzip
        cargo
    ];
  };
}
