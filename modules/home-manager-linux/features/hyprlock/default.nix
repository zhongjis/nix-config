{
  pkgs,
  config,
  ...
}: let
  uptime-sh = pkgs.writeShellScript "uptime-nixos" (builtins.readFile ./scripts/uptime-nixos.sh);
in {
  # hyprlock
  programs.hyprlock = {
    enable = true;
    extraConfig = with config.lib.stylix.colors;
    /*
    hyprlang
    */
      ''
        general {
            grace = 1
        }

        fingerprint {
          enabled = true
        }

        background {
            monitor =
            path = ${config.stylix.image}
            blur_size = 5
            blur_passes = 1 # 0 disables blurring
            noise = 0.0117
            contrast = 1.3000 # Vibrant!!!
            brightness = 0.8000
            vibrancy = 0.2100
            vibrancy_darkness = 0.0
        }

        input-field {
            monitor =
            size = 200, 50
            outline_thickness = 3
            dots_size = 0.33 # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.15 # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true
            dots_rounding = -1 # -1 default circle, -2 follow input-field rounding
            outer_color=rgb(${base0A})
            inner_color=rgb(${base08})
            font_color=rgb(${base05})
            fade_on_empty = true
            fade_timeout = 1000 # Milliseconds before fade_on_empty is triggered.
            placeholder_text = <i>Input Password...</i> # Text rendered in the input box when it's empty.
            hide_input = false
            rounding = -1 # -1 means complete rounding (circle/oval)
            check_color=rgb(${base03})
            fail_color=rgb(${base00})
            fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i> # can be set to empty
            fail_transition = 300 # transition time in ms between normal outer_color and fail_color
            capslock_color = -1
            numlock_color = -1
            bothlock_color = -1 # when both locks are active. -1 means don't change outer color (same for above)
            invert_numlock = false # change color if numlock is off
            swap_font_color = false # see below
            position = 0, -20
            halign = center
            valign = center
        }

        label {
            monitor =
            #clock
            text = cmd[update:1000] echo "$TIME"
            color = rgba(200, 200, 200, 1.0)
            font_size = 55
            font_family = Fira Semibold
            position = -100, 70
            halign = right
            valign = bottom
            shadow_passes = 5
            shadow_size = 10
        }

        label {
            monitor =
            text = $USER
            color = rgba(200, 200, 200, 1.0)
            font_size = 20
            font_family = Fira Semibold
            position = -100, 160
            halign = right
            valign = bottom
            shadow_passes = 5
            shadow_size = 10
        }
      '';
  };
}
