{
  lib,
  config,
  pkgs,
  ...
}: let
  plugin_dir = ./config/plugins;
  plugin_laptop_dir = ./config/plugins-laptop;
  plugin_desktop_dir = ./config/plugins-desktop;
in {
  options = {
    sketchybar.enable =
      lib.mkEnableOption "enables sketchybar";
  };

  config = lib.mkIf config.sketchybar.enable {
    # https://github.com/FelixKratz/dotfiles/tree/e6422df2bfe674a771f5e92b478e5999e945ccf0
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      config = ''
        #!/usr/bin/env zsh

        # This is used to determine if a monitor is used
        # Since the notch is -only- on the laptop, if a monitor isn't used,
        # then that means the internal display is used ¯\_(ツ)_/¯
        MAIN_DISPLAY=$(system_profiler SPDisplaysDataType | grep -B 3 'Main Display:' | awk '/Display Type/ {print $3}')

        if [[ $MAIN_DISPLAY = "Built-in" ]]; then
          FONT_FACE="JetBrainsMono Nerd Font"
          PLUGIN_DIR="${plugin_desktop_dir}"
          PLUGIN_SHARED_DIR="${plugin_dir}"

          SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

          sketchybar --bar \
              height=32 \
              color=0x66494d64 \
              margin=0 \
              sticky=on \
              padding_left=0 \
              padding_right=0 \
              notch_width=188 \
              display=main

          sketchybar --default \
              background.height=32 \
              icon.color=0xff24273a \
              icon.font="$FONT_FACE:Medium:20.0" \
              icon.padding_left=5 \
              icon.padding_right=5 \
              label.color=0xff24273a \
              label.font="$FONT_FACE:Bold:14.0" \
              label.y_offset=1 \
              label.padding_left=0 \
              label.padding_right=5

          sketchybar --add item current_space left \
              --set current_space \
              background.color=0xfff5a97f \
              label.drawing=off \
              script="$PLUGIN_SHARED_DIR/current_space.sh" \
              --subscribe current_space space_change mouse.clicked

          sketchybar --add item front_app left \
              --set front_app \
              background.color=0xffa6da95 \
              background.padding_left=0 \
              background.padding_right=0 \
              icon.y_offset=1 \
              label.drawing=no \
              script="$PLUGIN_SHARED_DIR/front_app.sh" \
              --add item front_app.separator left \
              --set front_app.separator \
              background.color=0x00000000 \
              icon= \
              icon.color=0xffa6da95 \
              icon.font="$FONT_FACE:Bold:23.0" \
              icon.padding_left=0 \
              icon.padding_right=0 \
              icon.y_offset=1 \
              label.drawing=no \
              --add item front_app.name left \
              --set front_app.name \
              background.color=0x00000000 \
              icon.drawing=off \
              label.font="$FONT_FACE:Bold:16.0" \
              label.color=0xffcad3f5 \
              label.padding_left=5

          sketchybar --add bracket front_app_bracket \
              front_app \
              front_app.separator \
              front_app.name \
              --subscribe front_app front_app_switched

          sketchybar --add item clock right \
              --set clock \
              icon=󰃰 \
              background.color=0xffed8796 \
              update_freq=10 \
              script="$PLUGIN_SHARED_DIR/clock.sh"

          sketchybar --add event spotify_change $SPOTIFY_EVENT \
              --add item spotify right \
              --set spotify \
              icon= \
              icon.y_offset=1 \
              label.drawing=off \
              label.padding_left=3 \
              script="$PLUGIN_DIR/spotify.sh" \
              --subscribe spotify spotify_change mouse.clicked

          sketchybar --update
          sketchybar --trigger space_change

        else

          FONT_FACE="JetBrainsMono Nerd Font"

          PLUGIN_DIR="${plugin_laptop_dir}"
          PLUGIN_SHARED_DIR="${plugin_dir}"

          SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

          sketchybar --bar \
              height=32 \
              color=0x00000000 \
              margin=0 \
              sticky=on \
              padding_left=23 \
              padding_right=23 \
              notch_width=188 \
              display=main

          # Alternatiive background colors
          # label.color=0xffffffff
          # background.color=0x9924273a
          sketchybar --default \
              background.color=0x66494d64 \
              background.corner_radius=5 \
              background.padding_right=5 \
              background.height=26 \
              icon.font="$FONT_FACE:Medium:15.0" \
              icon.padding_left=5 \
              icon.padding_right=5 \
              label.font="$FONT_FACE:Medium:12.0" \
              label.color=0xffcad3f5 \
              label.y_offset=0 \
              label.padding_left=0 \
              label.padding_right=5

          sketchybar --add event spotify_change $SPOTIFY_EVENT \
              --add item spotify e \
              --set spotify \
              icon= \
              icon.y_offset=1 \
              icon.font="$FONT_FACE:Bold:20.0" \
              label.drawing=off \
              label.padding_left=3 \
              script="$PLUGIN_DIR/spotify.sh" \
              --subscribe spotify spotify_change mouse.clicked

          sketchybar --add item current_space left \
              --set current_space \
              background.color=0xfff5a97f \
              icon.color=0xff24273a \
              label.drawing=off \
              script="$PLUGIN_SHARED_DIR/current_space.sh" \
              --subscribe current_space space_change mouse.clicked

          sketchybar --add item front_app left \
              --set front_app \
              background.color=0xffa6da95 \
              background.padding_left=0 \
              background.padding_right=0 \
              icon.y_offset=1 \
              icon.color=0xff24273a \
              label.drawing=no \
              script="$PLUGIN_SHARED_DIR/front_app.sh" \
              --add item front_app.separator left \
              --set front_app.separator \
              background.color=0x00000000 \
              background.padding_left=-3 \
              icon= \
              icon.color=0xffa6da95 \
              icon.font="$FONT_FACE:Bold:20.0" \
              icon.padding_left=0 \
              icon.padding_right=0 \
              icon.y_offset=1 \
              label.drawing=no \
              --add item front_app.name left \
              --set front_app.name \
              background.color=0x00000000 \
              background.padding_right=0 \
              icon.drawing=off \
              label.font="$FONT_FACE:Bold:12.0" \
              label.drawing=yes

          sketchybar --add item weather.moon q \
              --set weather.moon \
              background.color=0x667dc4e4 \
              background.padding_right=-1 \
              icon.color=0xff181926 \
              icon.font="$FONT_FACE:Bold:22.0" \
              icon.padding_left=4 \
              icon.padding_right=3 \
              label.drawing=off \
              --subscribe weather.moon mouse.clicked

          sketchybar --add item weather q \
              --set weather \
              icon= \
              icon.color=0xfff5bde6 \
              icon.font="$FONT_FACE:Bold:15.0" \
              update_freq=1800 \
              script="$PLUGIN_SHARED_DIR/weather.sh" \
              --subscribe weather system_woke

          sketchybar --add bracket front_app_bracket \
              front_app \
              front_app.separator \
              front_app.name \
              --subscribe front_app front_app_switched

          sketchybar --add item clock right \
              --set clock \
              icon=󰃰 \
              icon.color=0xffed8796 \
              update_freq=10 \
              script="$PLUGIN_SHARED_DIR/clock.sh"

          sketchybar --add item battery right \
              --set battery \
              update_freq=20 \
              script="$PLUGIN_DIR/battery.sh"

          sketchybar --add item volume right \
              --set volume \
              icon.color=0xff8aadf4 \
              label.drawing=true \
              script="$PLUGIN_SHARED_DIR/volume.sh" \
              --subscribe volume volume_change

          # osascript -e 'quit app "Rectangle"'
          # open -a Rectangle

          sketchybar --update
          sketchybar --trigger space_change
        fi
      '';
    };
  };
}
