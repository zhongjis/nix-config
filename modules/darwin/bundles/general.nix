{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ../../shared/packages
  ];
  nix.enable = false; # NOTE: use determinate nix

  myNixDarwin.nh.enable = lib.mkDefault true;
  myNixDarwin.determinate.enable = lib.mkDefault true;
  myNixDarwin.macos-system.enable = lib.mkDefault true;

  # for zsh auto completion
  environment.pathsToLink = ["/share/zsh"];

  # packages
  environment.systemPackages = with pkgs; [
    nh
    jq

    docker-compose
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "zshen";

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "nikitabobko/homebrew-tap" = inputs.aerospace-tap;
    };

    mutableTaps = true;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "none";
    };

    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      "bitwarden-cli"
      "sshuttle"
    ];

    casks = [
      # "flux"
      "box-drive"
      "caffeine"
      "appcleaner"
      "bartender"
      # "quicksilver"
      "alfred"
      "bitwarden"
      "ghostty"

      "obsidian"
      "spotify"
      "localsend"

      "google-chrome"
      "helium-browser"
    ];

    # AeroSpace's cask ships from a third-party tap. Homebrew now refuses to
    # load casks from untrusted taps, so grant explicit trust for this cask.
    extraConfig = ''
      cask "nikitabobko/tap/aerospace", trusted: true
    '';

    masApps = {
      Things3 = 904280696;
      Unclutter = 577085396;
    };
  };
}
