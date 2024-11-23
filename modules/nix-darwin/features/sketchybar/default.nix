{
  lib,
  config,
  pkgs,
  ...
}: let
  date-time-sh = pkgs.writeShellScriptBin "date-time.sh" ./plugins/date-time.sh;
  top-mem-sh = pkgs.writeShellScriptBin "top-mem.sh" ./plugins/top-mem.sh;
  cpu-sh = pkgs.writeShellScriptBin "cpu.sh" ./plugins/cpu.sh;
  caffeine-sh = pkgs.writeShellScriptBin "caffeine.sh" ./plugins/caffeine.sh;
  caffeine-click-sh = pkgs.writeShellScriptBin "caffeine-click.sh" ./plugins/caffeine-click.sh;
  battery-sh = pkgs.writeShellScriptBin "battery.sh" ./plugins/battery.sh;
  top-proc-sh = pkgs.writeShellScriptBin "top-proc.sh" ./plugins/top-proc.sh;
  spotify-indicator-sh = pkgs.writeShellScriptBin "spotify-indicator.sh" ./plugins/spotify-indicator.sh;
in {
  options = {
    sketchybar.enable =
      lib.mkEnableOption "enables sketchybar";
  };

  config = lib.mkIf config.sketchybar.enable {
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    services.sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        jq
        jetbrains-mono
      ];

      config = ''
        ############## BAR ##############
          sketchybar -m --bar \
            height=39 \
            position=top \
            padding_left=5 \
            padding_right=5 \
            color=0xff2e3440 \
            shadow=off \
            sticky=on \
            topmost=off

        ############## GLOBAL DEFAULTS ##############
          sketchybar -m --default \
            updates=when_shown \
            drawing=on \
            cache_scripts=on \
            icon.font="JetBrainsMono Nerd Font Mono:Bold:18.0" \
            icon.color=0xffffffff \
            label.font="JetBrainsMono Nerd Font Mono:Bold:12.0" \
            label.color=0xffeceff4 \
            label.highlight_color=0xff8CABC8

          ############## SPACE DEFAULTS ##############
          sketchybar -m --default \
            label.padding_left=5 \
            label.padding_right=2 \
            icon.padding_left=8 \
            label.padding_right=8

          ############## PRIMARY DISPLAY SPACES ##############
          # APPLE ICON
          sketchybar -m --add item apple left \
            --set apple icon= \
            --set apple icon.font="JetBrainsMono Nerd Font Mono:Regular:20.0" \
            --set apple label.padding_right=0 \

          # SPACE 1: WEB ICON
          sketchybar -m --add space web left \
            --set web icon= \
            --set web icon.highlight_color=0xff8CABC8 \
            --set web associated_space=1 \
            --set web icon.padding_left=5 \
            --set web icon.padding_right=5 \
            --set web label.padding_right=0 \
            --set web label.padding_left=0 \
            --set web label.color=0xffeceff4 \
            --set web background.color=0xff57627A  \
            --set web background.height=21 \
            --set web background.padding_left=12 \
            --set web click_script="open -a Zen \Browser.app" \

          # SPACE 2: CODE ICON
          sketchybar -m --add space code left \
            --set code icon= \
            --set code associated_space=2 \
            --set code icon.padding_left=5 \
            --set code icon.padding_right=5 \
            --set code label.padding_right=0 \
            --set code label.padding_left=0 \
            --set code label.color=0xffeceff4 \
            --set code background.color=0xff57627A  \
            --set code background.height=21 \
            --set code background.padding_left=7 \
            --set code click_script="open -a kitty.app" \

          # SPACE 3: MUSIC ICON
          sketchybar -m --add space music left \
            --set music icon= \
            --set music icon.highlight_color=0xff8CABC8 \
            --set music associated_display=1 \
            --set music associated_space=5 \
            --set music icon.padding_left=5 \
            --set music icon.padding_right=5 \
            --set music label.padding_right=0 \
            --set music label.padding_left=0 \
            --set music label.color=0xffeceff4 \
            --set music background.color=0xff57627A  \
            --set music background.height=21 \
            --set music background.padding_left=7 \
            --set music click_script="open -a Spotify.app" \

          # SPOTIFY STATUS
          # CURRENT SPOTIFY SONG
          # Adding custom events which can listen on distributed notifications from other running processes
          sketchybar -m --add event spotify_change "com.spotify.client.PlaybackStateChanged" \
            --add item spotify_indicator left \
            --set spotify_indicator background.color=0xff57627A  \
            --set spotify_indicator background.height=21 \
            --set spotify_indicator background.padding_left=7 \
            --set spotify_indicator script="${spotify-indicator-sh}/bin/spotify-indicator.sh" \
            --set spotify_indicator click_script="osascript -e 'tell application \"Spotify\" to pause'" \
            --subscribe spotify_indicator spotify_change \

        ############## ITEM DEFAULTS ###############
          sketchybar -m --default \
            label.padding_left=2 \
            icon.padding_right=2 \
            icon.padding_left=6 \
            label.padding_right=6

        ############## RIGHT ITEMS ##############
          # DATE TIME
          sketchybar -m --add item date_time right \
            --set date_time icon= \
            --set date_time icon.padding_left=8 \
            --set date_time icon.padding_right=0 \
            --set date_time label.padding_right=9 \
            --set date_time label.padding_left=6 \
            --set date_time label.color=0xffeceff4 \
            --set date_time update_freq=20 \
            --set date_time background.color=0xff57627A \
            --set date_time background.height=21 \
            --set date_time background.padding_right=12 \
            --set date_time script="${date-time-sh}/bin/date-time.sh" \

          # Battery STATUS
          sketchybar -m --add item battery right \
            --set battery icon.font="JetBrainsMono Nerd Font Mono:Bold:10.0" \
            --set battery icon.padding_left=8 \
            --set battery icon.padding_right=8 \
            --set battery label.padding_right=8 \
            --set battery label.padding_left=0 \
            --set battery label.color=0xffffffff \
            --set battery background.color=0xff57627A  \
            --set battery background.height=21 \
            --set battery background.padding_right=7 \
            --set battery update_freq=10 \
            --set battery script="${battery-sh}/bin/battery.sh" \

          # RAM USAGE
          sketchybar -m --add item topmem right \
            --set topmem icon= \
            --set topmem icon.padding_left=8 \
            --set topmem icon.padding_right=0 \
            --set topmem label.padding_right=8 \
            --set topmem label.padding_left=6 \
            --set topmem label.color=0xffeceff4 \
            --set topmem background.color=0xff57627A  \
            --set topmem background.height=21 \
            --set topmem background.padding_right=7 \
            --set topmem update_freq=2 \
            --set topmem script="${top-mem-sh}/bin/top-mem.sh" \

          # CPU USAGE
          sketchybar -m --add item cpu_percent right \
            --set cpu_percent icon= \
            --set cpu_percent icon.padding_left=8 \
            --set cpu_percent icon.padding_right=0 \
            --set cpu_percent label.padding_right=8 \
            --set cpu_percent label.padding_left=6 \
            --set cpu_percent label.color=0xffeceff4 \
            --set cpu_percent background.color=0xff57627A  \
            --set cpu_percent background.height=21 \
            --set cpu_percent background.padding_right=7 \
            --set cpu_percent update_freq=2 \
            --set cpu_percent script="${cpu-sh}/bin/cpu.sh" \

          # CAFFEINE
          sketchybar -m --add item caffeine right \
            --set caffeine icon.padding_left=8 \
            --set caffeine icon.padding_right=0 \
            --set caffeine label.padding_right=0 \
            --set caffeine label.padding_left=6 \
            --set caffeine label.color=0xffeceff4 \
            --set caffeine background.color=0xff57627A  \
            --set caffeine background.height=21 \
            --set caffeine background.padding_right=7 \
            --set caffeine script="${caffeine-sh}/bin/caffeine.sh" \
            --set caffeine click_script="${caffeine-click-sh}/bin/caffeine-click.sh" \

          # TOP PROCESS
          sketchybar -m --add item topproc right \
            --set topproc drawing=on \
            --set topproc label.padding_right=10 \
            --set topproc update_freq=15 \
            --set topproc script="${top-proc-sh}/bin/topproc.sh"

        ###################### CENTER ITEMS ###################


        ############## FINALIZING THE SETUP ##############
        sketchybar -m --update

        # HOT RELOAD
        sketchybar --hotload true

        echo "sketchybar configuration loaded.."
      '';
    };
  };
}
