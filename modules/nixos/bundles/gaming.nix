{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.nix-gaming.nixosModules.pipewireLowLatency
  ];

  services.pipewire.lowLatency.enable = true;

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 15;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:'Game Mode' 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:'Game Mode' 'GameMode stopped'";
      };
    };
  };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = false;
    platformOptimizations.enable = false;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  environment.systemPackages = with pkgs;
    [
      wineWayland
      bottles
      mangohud
      protonup-qt
      dxvk
      heroic

      # parsec-bin
      vesktop # discord client

      # steamtinkerlaunch %command%
      steamtinkerlaunch
    ]
    ++ [
      pkgs.stable.gamescope
    ];

  # dota 2: LD_PRELOAD= gamescope -W 3440 -H 1440 --force-grab-cursor --expose-wayland --rt -r 144 --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" gamemoderun %command%
}
