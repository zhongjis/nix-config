{
  pkgs,
  config,
  inputs,
  lib,
  inputs,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      experimental-features = "nix-command flakes";
    };
  };

  myHomeManager.neovim.enable = lib.mkDefault true;
  myHomeManager.stylix.enable = lib.mkDefault true;
  myHomeManager.services.tmux.enable = lib.mkDefault true;
  myHomeManager.zellij.enable = lib.mkDefault false;
  myHomeManager.alacritty.enable = lib.mkDefault false;
  myHomeManager.cht-sh.enable = lib.mkDefault true;
  myHomeManager.direnv.enable = lib.mkDefault true;
  myHomeManager.fzf.enable = lib.mkDefault true;
  myHomeManager.ghostty.enable = lib.mkDefault true;
  myHomeManager.wezterm.enable = lib.mkDefault false;
  myHomeManager.git.enable = lib.mkDefault true;
  myHomeManager.jujutsu.enable = lib.mkDefault true;
  myHomeManager.kitty.enable = lib.mkDefault true;
  myHomeManager.kubernetes.enable = lib.mkDefault true;
  myHomeManager.lazygit.enable = lib.mkDefault true;
  myHomeManager.ai-tools.enable = lib.mkDefault true;
  myHomeManager.rg.enable = lib.mkDefault true;
  myHomeManager.sops.enable = lib.mkDefault true;
  myHomeManager.ssh.enable = lib.mkDefault true;
  myHomeManager.yazi.enable = lib.mkDefault true;
  myHomeManager.zsh.enable = lib.mkDefault true;
  myHomeManager.starship.enable = lib.mkDefault true;
  myHomeManager.zed.enable = lib.mkDefault true;

  programs.btop.enable = lib.mkDefault true;
  programs.bun.enable = lib.mkDefault true;
  programs.zen-browser.enable = lib.mkDefault false;

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.openkanban
  ];

  home.sessionVariables = {
    FLAKE = "${config.home.homeDirectory}/personal/nix-config";
  };

  home.packages =
    lib.optional
    (inputs.self.packages.${pkgs.stdenv.hostPlatform.system} ? agent-of-empires)
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.agent-of-empires;
}
