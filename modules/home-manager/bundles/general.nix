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
  myHomeManager.tmux.enable = lib.mkDefault true;
  myHomeManager.alacritty.enable = lib.mkDefault true;
  myHomeManager.fastfetch.enable = lib.mkDefault true;
  myHomeManager.git.enable = lib.mkDefault true;
  myHomeManager.k9s.enable = lib.mkDefault true;
  myHomeManager.kitty.enable = lib.mkDefault true;
  myHomeManager.lazygit.enable = lib.mkDefault true;
  myHomeManager.sops.enable = lib.mkDefault true;
  myHomeManager.thefuck.enable = lib.mkDefault true;
  myHomeManager.yazi.enable = lib.mkDefault true;

  myHomeManager.zsh.enable = lib.mkDefault true;
  myHomeManager.fzf.enable = lib.mkDefault true;
  myHomeManager.eza.enable = lib.mkDefault true;
  myHomeManager.zoxide.enable = lib.mkDefault true;
  myHomeManager.carapace.enable = lib.mkDefault true;
  myHomeManager.bat.enable = lib.mkDefault true;
  myHomeManager.starship.enable = lib.mkDefault true;

  home.packages = with pkgs; [
    obsidian

    sops
    awscli2
    gh

    unzip
    zip
    wget

    spotify

    # fonts
    font-awesome
    sketchybar-app-font
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "Agave"
        "JetBrainsMono"
      ];
    })
  ];

  home.sessionVariables = {
    FLAKE = "${config.home.homeDirectory}/personal/nix-config";
  };
}
