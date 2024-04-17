{ inputs, pkgs, currentSystemUser, ... }:

{
  imports =
    [
      inputs.home-manager.darwinModules.default
      ../common.nix
      ../../modules/nix-darwin
    ];

  users.users.${currentSystemUser} = {
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
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
      "itsycal"
      "box-drive"

      # dev tools
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
  environment.systemPackages = with pkgs; [
    terraform-versions."1.5.2"
    docker_26

    # **java**
    maven
    jdk

    bitwarden-cli
    php
    kubectl
    kubelogin
    python3
    neofetch
  ];

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
