{
  inputs,
  pkgs,
  currentSystemUser,
  ...
}: let
  unstable_pkgs = with pkgs.unstable; [
    # placeholder
  ];
in {
  imports = [
    ../common.nix
    ../../modules/nix-darwin
  ];

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 14d --keep 24";
    };
  };

  users.users.${currentSystemUser} = {
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Dock
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.24;
    autohide-time-modifier = 1.0;
    magnification = false;
    mru-spaces = false;
    orientation = "left";
    show-recents = false;

    # hot corner
    wvous-br-corner = 1; # disabled
    wvous-bl-corner = 1; # disabled
    wvous-tr-corner = 1; # disabled
    wvous-tl-corner = 1; # disabled
  };

  # Finder
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    FXDefaultSearchScope = "SCcf"; # this folder
    FXPreferredViewStyle = "Nlsv"; # list view
    QuitMenuItem = true; # allow quit finder
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  system.defaults.universalaccess.reduceMotion = true;

  # TODO: need to emulate shortcuts for mission control, including all swtich desktops

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    casks = [
      # productivity
      "bartender"
      "bitwarden"
      "flux"
      "github"
      "spotify"
      "box-drive"
      "google-chrome"
      "dash"
      "raycast"
      "arc"
      "alfred"

      # dev tools
      "docker"
      "sublime-merge"
      "charles"
      "devtoys"
      "intellij-idea"
      "mongodb-compass"
    ];

    masApps = {
      Things3 = 904280696;
      Unclutter = 577085396;
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [
      raycast

      mongosh
      terraform-versions."1.6.6"

      # **java**
      maven
      jdk

      bitwarden-cli
      php

      kubectl
      kubelogin

      vault

      python312
      python312Packages.pip

      redis

      azure-cli
    ]
    ++ unstable_pkgs;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
