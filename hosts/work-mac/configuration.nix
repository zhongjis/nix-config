{ inputs, pkgs, ... }:
let
     pkgs = import (builtins.fetchGit {
         # Descriptive name to make the store path easier to identify
         name = "terraform-1-5-2";
         url = "https://github.com/NixOS/nixpkgs/";
         ref = "refs/heads/nixpkgs-unstable";
         rev = "5a8650469a9f8a1958ff9373bd27fb8e54c4365d";
     }) {};

     myPkg = pkgs.terraform;
in
{
  imports = 
    [ 
      inputs.home-manager.darwinModules.default
      ../../modules/nix-darwin/skhd
      ../../modules/nix-darwin/yabai
      ../common.nix
    ];

  users.users.zshen = {
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs; };
    users = {
      zshen = import ./home.nix;
    };
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    (nerdfonts.override { 
        fonts = [ 
         "FiraCode" 
         "DroidSansMono" 
         "Agave"
         "JetBrainsMono"
        ]; 
    })
  ];

  homebrew = {
    enable = true;
    casks = [
      "alacritty"
      "alfred"
      "bartender"
      "bitwarden"
      "caffeine"
      "charles"
      "cheatsheet"
      "devdocs"
      "devtoys"
      "docker"
      "dropbox"
      "flux"
      "github"
      "spotify"
      "mongodb-compass"
      "microsoft-openjdk11"
      "itsycal"
      "intellij-idea"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    myPkg.terraform
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

