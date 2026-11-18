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
    # package = pkgs.gamescope_git;
    # capSysNice wrapper dies inside Steam's sandbox (no_new_privs):
    # "failed to inherit capabilities: Operation not permitted"
    capSysNice = false;
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
    gamescope
    # Vulkan WSI layer: games inside gamescope only see HDR swapchains with it
    gamescope-wsi
    mangohud
    protonup-qt
    dxvk

    heroic
    bottles

    # parsec-bin
    vesktop # discord client

    # steamtinkerlaunch %command%
    steamtinkerlaunch
  ];

  # gamescope + HDR (ASUS PG27UCDM 4K 240Hz): LD_PRELOAD= gamescope -W 3840 -H 2160 -r 240 --hdr-enabled --force-grab-cursor --expose-wayland --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" DXVK_HDR=1 gamemoderun %command%
  # dota 2 - no gamescope: DRI_PRIME=1 gamemoderun %command%
}
