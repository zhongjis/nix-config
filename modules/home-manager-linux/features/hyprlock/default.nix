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
            size = 180, 40
            outline_thickness = 3
            dots_size = 0.33 # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.15 # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true
            check_color=rgb(${base03})
            fail_color=rgb(${base00})
            font_color=rgb(${base05})
            inner_color=rgb(${base08})
            outer_color=rgb(${base0A})
            fade_on_empty = true
            placeholder_text = <i>Password...</i> # Text rendered in the input box when it's empty.
            hide_input = false
            position = 0, 230
            halign = center
            valign = bottom
        }

        # DATE
        label {
            monitor =
            text = cmd[update:18000000] echo "<b> "$(date +'%A, %-d %B %Y')" </b>"
            color = rgb(184, 192, 224)
            font_size = 14
            font_family = Noto Nastaliq Urdu
            position = 0, -250
            halign = center
            valign = top
        }

        # TIME HR
        label {
            monitor =
            text = cmd[update:1000] echo -e "$(date +"%I")"
            color = rgb(245, 189, 230)
            shadow_size = 3
            shadow_color = rgb(0,0,0)
            shadow_boost = 1.2
            font_size = 180
            font_family = JetBrains Mono Nerd Font 10
            position = 0, -255
            halign = center
            valign = top
            zindex = 5
        }

        # TIME MIN
        label {
            monitor =
            text = cmd[update:1000] echo -e "$(date +"%M")"
            color = rgb(145, 215, 227)
            font_size = 180
            font_family = JetBrains Mono Nerd Font 10
            position = 0, -450
            halign = center
            valign = top
            zindex = 5
        }

        # TIME SEC
        label {
            monitor =
            text = cmd[update:1000] echo -e "$(date +"%S")"
            color = rgb(184, 192, 224)
            shadow_size = 3
            shadow_color = rgb(0,0,0)
            shadow_boost = 1.2
            font_size = 20
            font_family = JetBrains Mono Nerd Font 10
            position = 150, -660
            halign = center
            valign = top
            zindex = 5
        }

        # User
        label {
            monitor =
            text =$USER
            color = rgb(184, 192, 224)
            font_size = 45
            font_family = Inter Display Medium

            position = 60, 100
            halign = center
            valign = bottom
        }

        # Uptime
        label {
            monitor =
            text = cmd[update:60000] echo "<b> "$(uptime -p || ${uptime-sh})" </b>"
            color = rgb(184, 192, 224)
            font_size = 11
            font_family = JetBrains Mono Nerd Font 10
            position = 0, -1000
            halign = center
            valign = top
        }
      '';
  };
}
