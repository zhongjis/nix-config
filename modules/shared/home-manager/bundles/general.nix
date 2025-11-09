{
  pkgs,
  config,
  lib,
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
  myHomeManager.tmux.enable = lib.mkDefault true;
  myHomeManager.zellij.enable = lib.mkDefault false;
  myHomeManager.alacritty.enable = lib.mkDefault false;
  myHomeManager.cht-sh.enable = lib.mkDefault true;
  myHomeManager.direnv.enable = lib.mkDefault true;
  myHomeManager.fzf.enable = lib.mkDefault true;
  myHomeManager.ghostty.enable = lib.mkDefault true;
  myHomeManager.wezterm.enable = lib.mkDefault true;
  myHomeManager.git.enable = lib.mkDefault true;
  myHomeManager.kitty.enable = lib.mkDefault true;
  myHomeManager.kubernetes.enable = lib.mkDefault true;
  myHomeManager.lazygit.enable = lib.mkDefault true;
  myHomeManager.opencode.enable = lib.mkDefault true;
  myHomeManager.claude-code.enable = lib.mkDefault true;
  myHomeManager.rg.enable = lib.mkDefault true;
  myHomeManager.sops.enable = lib.mkDefault true;
  myHomeManager.ssh.enable = lib.mkDefault true;
  myHomeManager.yazi.enable = lib.mkDefault true;
  myHomeManager.zsh.enable = lib.mkDefault true;

  myHomeManager.starship.enable = lib.mkDefault true;

  programs.btop.enable = lib.mkDefault true;

  programs.zen-browser.enable = lib.mkDefault true;

  home.sessionVariables = {
    FLAKE = "${config.home.homeDirectory}/personal/nix-config";
  };
}
