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

    extraLuaConfig = ''
        vim.o.scrolloff = 8
        vim.o.number = true
        vim.o.cursorline = true
        vim.o.tabstop = 4
        vim.o.softtabstop = 4
        vim.o.shiftwidth = 4
        vim.o.expandtab = true
        vim.o.smartindent = true

        ${builtins.readFile ./kickstart.lua}
    '';
  };
}
