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
    capSysNice = true;
  };

  programs.steam = {
    enable = true;

    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  environment.systemPackages = with pkgs;
    [
      bottles
      mangohud
      protonup-qt
      heroic

      # parsec-bin
      vesktop # discord client

      # steamtinkerlaunch %command%
      steamtinkerlaunch
    ]
    ++ (with pkgs.stable; []);

  # dota 2: LD_PRELOAD= gamescope -W 3440 -H 1440 --force-grab-cursor --expose-wayland --rt -r 144 --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" gamemoderun %command%
  # dota 2 test: LD_PRELOAD= gamescope -W 3440 -H 1440 --force-grab-cursor --hdr-enabled --expose-wayland --rt -r 144 --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" gamemoderun %command%
  # lutris: gamescope -h 1200 -H 1600 -w 1920 -W 2560 -F fsr -f --hdr-enabled --fsr-sharpness 20 -- prismlauncher
}
