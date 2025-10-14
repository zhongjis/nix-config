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

  nix.enable = false; # NOTE: use determinate nix

  myNixDarwin.nh.enable = lib.mkDefault true;
  myNixDarwin.determinate.enable = lib.mkDefault true;
  myNixDarwin.macos-system.enable = lib.mkDefault true;

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
    jq

    docker-compose

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

    mutableTaps = false;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      "bitwarden-cli"
    ];

    casks = [
      # "flux"
      "box-drive"
      "caffeine"
      "aerospace"
      "appcleaner"
      # "quicksilver"
      "alfred"
      "bitwarden"
      "ghostty"
      "claude-code"

      "obsidian"
      "spotify"
      "google-chrome"
      "zen"
    ];

    masApps = {
      Things3 = 904280696;
      Unclutter = 577085396;
    };
  };
}
