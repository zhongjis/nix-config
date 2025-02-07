{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  myNixDarwin.aerospace.enable = lib.mkDefault false;
  myNixDarwin.nh.enable = lib.mkDefault true;

  # for zsh auto completion
  environment.pathsToLink = ["/share/zsh"];

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  # packages
  environment.systemPackages = with pkgs; [
    nh

    google-chrome

    # fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.agave
    font-awesome
    sketchybar-app-font
    cm_unicode
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inter
    font-awesome
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "zshen";
    autoMigrate = true;

    taps = {
      "homebrew/core" = inputs.homebrew-core;
      "homebrew/cask" = inputs.homebrew-cask;
      "homebrew/bundle" = inputs.homebrew-bundle;
      "nikitabobko/tap" = inputs.aerospace-tap;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    brews = [
      "bitwarden-cli"
      "jq"

      "podman"
      "podman-compose"
    ];

    casks = [
      # productivity
      "flux"
      "box-drive"
      "bitwarden"
      "alfred"
      "caffeine"
      "aerospace"

      "zen-browser"

      "appcleaner"

      # duplicates: already included in full-system. but adding them for alfred app
      # FIXME: migrate to use https://gist.github.com/elliottminns/211ef645ebd484eb9a5228570bb60ec3
      "ghostty"
      "obsidian"
      "spotify"
    ];

    masApps = {
      Things3 = 904280696;
      Unclutter = 577085396;
    };
  };

  # Keyboard
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;
  };

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

  # NOTE: need to allow full diskaccess for terminal emulator for the following
  system.defaults.universalaccess.reduceMotion = true;
}
