{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.nix-gaming.nixosModules.pipewireLowLatency
  ];

  myNixOS.lact.enable = lib.mkDefault true;
  services.pipewire.lowLatency.enable = true;

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    package = pkgs.gamescope_git;
    capSysNice = true;
  };

  programs.steam = {
    enable = true;
    # gamescopeSession.enable = true;

    platformOptimizations.enable = true;

    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    extraPackages = with pkgs; [
      SDL2
    ];
  };

  environment.systemPackages = with pkgs; [
    gamescope_git
    mangohud_git
    protonup-qt
    dxvk

    heroic
    bottles

    # parsec-bin
    vesktop # discord client

    # steamtinkerlaunch %command%
    steamtinkerlaunch
  ];

  # dota 2: LD_PRELOAD= gamescope -W 3440 -H 1440 --force-grab-cursor --expose-wayland --rt -r 144 --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" gamemoderun %command%
}
