{
  lib,
  config,
  pkgs,
  ...
}: {
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

      home.file.".config/sketchybar/plugins/battery.sh".text = ''
        ${builtins.readFile ./plugins/battery.sh}
      '';

      home.file.".config/sketchybar/plugins/spotify.sh".text = ''
        ${builtins.readFile ./plugins/spotify.sh}
      '';

      home.file.".config/sketchybar/plugins/clock.sh".text = ''
        ${builtins.readFile ./plugins/clock.sh}
      '';

      home.file.".config/sketchybar/plugins/current_space.sh".text = ''
        ${builtins.readFile ./plugins/current_space.sh}
      '';

      home.file.".config/sketchybar/plugins/front_app.sh".text = ''
        ${builtins.readFile ./plugins/front_app.sh}
      '';

      home.file.".config/sketchybar/plugins/volume.sh".text = ''
        ${builtins.readFile ./plugins/volume.sh}
      '';

      home.file.".config/sketchybar/plugins/weather.sh".text = ''
        ${builtins.readFile ./plugins/weather.sh}
      '';

      extraPackages = with pkgs; [
        jq
      ];
    };
  };
}
