{
  config,
  lib,
  pkgs,
  ...
}: {
  # f.lux-style blue light filter for Hyprland
  # Based on f.lux "Recommended Colors" preset:
  # - Daytime: 6500K (neutral, no color shift)
  # - Evening: 3400K (warm, reduces eye strain)
  # - Bedtime: 1900K (very warm, minimal blue light)
  services.hyprsunset = {
    enable = true;
    # UWSM doesn't activate graphical-session.target, so bind to default.target
    systemdTarget = "default.target";

    settings = {
      # Morning - neutral daylight (no color shift)
      # 7:00 AM: Start of day, full brightness
      profile = [
        {
          time = "07:00";
          identity = true; # 6500K equivalent - no color change
        }
        # Evening transition - warm light
        # 6:00 PM: Begin evening warmth (sunset-ish)
        {
          time = "18:00";
          temperature = 4500; # Gentle transition
        }
        # Night - warmer
        # 8:00 PM: Full evening mode
        {
          time = "20:00";
          temperature = 3400; # f.lux "Nighttime" equivalent
        }
        # Bedtime - very warm, minimal blue light
        # 10:00 PM: Preparing for sleep
        {
          time = "22:00";
          temperature = 2700; # Deep warm
        }
        # Late night - maximum warmth
        # 11:00 PM: Full bedtime mode
        {
          time = "23:00";
          temperature = 1900; # f.lux "Bedtime" equivalent - candlelight
        }
      ];
    };
  };
}
