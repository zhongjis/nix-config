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

  programs.gamescope.enable = true;

  programs.steam = {
    enable = true;

    platformOptimizations.enable = false;

    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    extraPackages = with pkgs; [
      SDL2
      gamescope
      er-patcher
    ];
    protontricks.enable = true;
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
    ++ (with pkgs.stable; [
      ]);

  # dota 2: LD_PRELOAD= gamescope -W 3440 -H 1440 --force-grab-cursor --expose-wayland --rt -r 144 --mangoapp -f -- env LD_PRELOAD="$LD_PRELOAD" gamemoderun %command%
}
