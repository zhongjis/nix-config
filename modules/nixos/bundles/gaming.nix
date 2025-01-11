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
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:'Game Mode' 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:'Game Mode' 'GameMode stopped'";
      };
    };
  };
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    platformOptimizations.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bottles
    mangohud
    gamescope
    protonup-qt
    dxvk
    heroic

    # parsec-bin
    webcord

    # steamtinkerlaunch %command%
    steamtinkerlaunch
  ];

  # dota 2: LD_PRELOAD="" gamescope -W 3440 -H 1440 -r 90 --hdr-enabled --force-grab-cursor --expose-wayland --mangoapp -f -- gamemoderun %command%
  # frost punk 2: gamemoderun PROTON_ENABLE_NVAPI=1 PROTON_HIDE_NVIDIA_GPU=0 %command%
}
