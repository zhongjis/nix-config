{
  pkgs,
  lib,
  ...
}: {
  myNixDarwin.aerospace.enable = lib.mkDefault false;
  myNixDarwin.nh.enable = lib.mkDefault true;

  # for zsh auto completion
  environment.pathsToLink = ["/share/zsh"];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    taps = [
      "nikitabobko/tap"
    ];

    brews = [
      "bitwarden-cli"
      "jq"
    ];

    casks = [
      # productivity
      "bartender"
      "flux"
      "box-drive"
      "bitwarden"
      "alfred"
      "caffeine"
      "aerospace"

      "google-chrome"
      "zen-browser"

      # dev tools
      "dash"
      "docker"
      "charles"
      "devtoys"
      "mongodb-compass"
      "intellij-idea"
      "sublime-merge"
      "zed"

      # duplicates: already included in full-system. but adding them for alfred app
      "kitty"
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
