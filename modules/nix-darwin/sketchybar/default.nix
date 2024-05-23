{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs) writeTextFile;

  batteryScript = writeTextFile {
    name = "sketchybar-battery.sh";
    text = ''
      ${builtins.readFile ./plugins/battery.sh}
    '';
  };

  spotifyScript = writeTextFile {
    name = "sketchybar-spotify.sh";
    text = ''
      ${builtins.readFile ./plugins/spotify.sh}
    '';
  };

  clockScript = writeTextFile {
    name = "sketchybar-clock.sh";
    text = ''
      ${builtins.readFile ./plugins/clock.sh}
    '';
  };

  current_spaceScript = writeTextFile {
    name = "sketchybar-current-space.sh";
    text = ''
      ${builtins.readFile ./plugins/current_space.sh}
    '';
  };

  front_appScript = writeTextFile {
    name = "sketchybar-front-app.sh";
    text = ''
      ${builtins.readFile ./plugins/front_app.sh}
    '';
  };

  volumeScript = writeTextFile {
    name = "sketchybar-volume.sh";
    text = ''
      ${builtins.readFile ./plugins/volume.sh}
    '';
  };

  weatherScript = writeTextFile {
    name = "sketchybar-weather.sh";
    text = ''
      ${builtins.readFile ./plugins/weather.sh}
    '';
  };
in {
  options = {
    sketchybar.enable =
      lib.mkEnableOption "enables sketchybar";
  };

  config = lib.mkIf config.sketchybar.enable {
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    services.sketchybar = {
      enable = true;
      config = ''
        ${builtins.readFile ./sketchybarrc}
      '';

      extraPackages = with pkgs; [
        jq
      ];
    };

    environment.etc = {
      ".config/sketchybar/plugins/battery.sh".source = "${batteryScript}";
      ".config/sketchybar/plugins/spotify.sh".source = "${spotifyScript}";
      ".config/sketchybar/plugins/clock.sh".source = "${clockScript}";
      ".config/sketchybar/plugins/current_space.sh".source = "${current_spaceScript}";
      ".config/sketchybar/plugins/front_app.sh".source = "${front_appScript}";
      ".config/sketchybar/plugins/volume.sh".source = "${volumeScript}";
      ".config/sketchybar/plugins/weather.sh".source = "${weatherScript}";
    };
  };
}
