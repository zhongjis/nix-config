{
  pkgs,
  config,
  ...
}: let
  uptime-sh = pkgs.writeShellScript "uptime-nixos" (builtins.readFile ./scripts/uptime-nixos.sh);
in {
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # hyprlock
  programs.hyprlock = {
    enable = true;
    extraConfig = with config.lib.stylix.colors;
    /*
    hyprlang
    */
      ''
        background {
            monitor =
            path = ${config.stylix.image}
            blur_passes = 2
            contrast = 1
            brightness = 0.5
            vibrancy = 0.2
            vibrancy_darkness = 0.2
        }

        general {
            no_fade_in = true
            no_fade_out = true
            hide_cursor = false
            grace = 0
            disable_loading_bar = true
        }

        auth {
            pam:enabled = true
            fingerprint:enabled = true
            fingerprint:ready_message = Place your finger on the sensor
            fingerprint:present_message = Scanning finger
        }

        # INPUT FIELD
        input-field {
            monitor =
            size = 250, 60
            outline_thickness = 2

            dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.35 # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true

            outer_color=rgb(${base0A})
            inner_color=rgb(${base02})

            font_color=rgb(${base05})
            fade_on_empty = true
            rounding = -1

            check_color=rgb(${base0A})
            fail_color=rgb(${base08})
            fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i> # can be set to empty

            fail_transition = 300 # transition time in ms between normal outer_color and fail_color
            hide_input = false

            position = 0, -200
            halign = center
            valign = center
        }

        # DATE
        label {
          monitor =
          text = cmd[update:1000] echo "$(date +"%A, %B %d")"
          color = rgba(242, 243, 244, 0.75)
          font_size = 22
          font_family = JetBrains Mono
          position = 0, 300
          halign = center
          valign = center
        }

        # TIME
        label {
          monitor =
          text = cmd[update:1000] echo "$(date +"%-I:%M")"
          color = rgba(242, 243, 244, 0.75)
          font_size = 95
          font_family = JetBrains Mono Extrabold
          position = 0, 200
          halign = center
          valign = center
        }

        label {
            monitor =
            text = cmd[update:1000] echo "$(${pkgs.acpi}/bin/acpi -- -b | cut -d ',' -f1,2)"
            color = $foreground
            font_size = 24
            font_family = JetBrains Mono
            position = -90, -10
            halign = right
            valign = top
        }
      '';
  };
}
