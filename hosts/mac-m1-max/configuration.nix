{
  inputs,
  pkgs,
  currentSystemUser,
  ...
}: let
  unstable_pkgs = with pkgs.unstable; [
    azure-cli
  ];
in {
  imports = [
    inputs.home-manager.darwinModules.default
    ../common.nix
    ../../modules/nix-darwin
  ];

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
  };

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
      "alfred"
      "bartender"
      "bitwarden"
      "flux"
      "github"
      "spotify"
      "box-drive"
      "google-chrome"

      # dev tools
      "docker"
      "sublime-merge"
      "alacritty"
      "charles"
      "devtoys"
      "intellij-idea"
      "mongodb-compass"
    ];
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
