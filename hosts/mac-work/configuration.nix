{ inputs, pkgs, ... }:

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
    font-awesome
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
      # productivity
      "alfred"
      "bartender"
      "bitwarden"
      "caffeine"
      "flux"
      "github"
      "spotify"
      "itsycal"
      "box-drive"

      # dev tools
      "alacritty"
      "charles"
      "microsoft-openjdk11"
      "devtoys"
      "docker"
      "intellij-idea"
      "mongodb-compass"
    ];
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    terraform-versions."1.5.2"
    kubectl
    kubelogin
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

