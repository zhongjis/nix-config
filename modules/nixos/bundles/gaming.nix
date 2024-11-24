{pkgs, ...}: {
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.gamemode = {
    enable = true;
    settings = {
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode stopped'";
      };
    };
  };
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    gamescope
    protonup

    # parsec-bin
    discord

    # steamtinkerlaunch %command%
    steamtinkerlaunch
  ];
}
