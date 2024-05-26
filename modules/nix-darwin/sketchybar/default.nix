{
  lib,
  config,
  pkgs,
  ...
}: let
  sketchybar-helper = pkgs.callPackage ../../../packages/sketchybar-helper {};
  colors = ./config/colors.sh;
  icons = ./config/icons.sh;
  plugin_dir = ./config/plugins;
  item_dir = ./config/items;
in {
  options = {
    sketchybar.enable =
      lib.mkEnableOption "enables sketchybar";
  };

  config = lib.mkIf config.sketchybar.enable {
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    # Helper for CPU
    launchd.user.agents.sketchybar-helper = {
      path = [sketchybar-helper config.environment.systemPath];
      serviceConfig.ProgramArguments = [
        "/bin/sh"
        "-c"
        "source ${colors} && ${sketchybar-helper}/bin/sketchybar-helper git.zshen.helper"
      ];
      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      extraPackages = with pkgs; [
        jq
      ];

      config = ''
        #!/usr/bin/env bash
        # https://github.com/FelixKratz/dotfiles/tree/e6288b3f4220ca1ac64a68e60fced2d4c3e3e20b

        source "${colors}" # Loads all defined colors
        source "${icons}" # Loads all defined icons

        PLUGIN_DIR="${plugin_dir}"
        ITEM_DIR="${item_dir}"

        FONT="JetBrainsMono Nerd Font"
        PADDINGS=3 # All paddings use this value (icon, label, background)

        # Setting up and starting the helper process
        HELPER=git.zshen.helper

        ##### Bar Appearance #####
        # Configuring the general appearance of the bar, these are only some of the
        # options available. For all options see:
        # https://felixkratz.github.io/SketchyBar/config/bar
        # If you are looking for other colors, see the color picker:
        # https://felixkratz.github.io/SketchyBar/config/tricks#color-picker
        bar=(
          height=39
          color=$BAR_COLOR
          shadow=on
          position=top
          sticky=on
          padding_right=10
          padding_left=10
          corner_radius=9
          y_offset=10
          margin=10
          blur_radius=20
          notch_width=0
        )

        sketchybar --bar "''${bar[@]}"

        ##### Changing Defaults #####
        # We now change some default values that are applied to all further items
        # For a full list of all available item properties see:
        # https://felixkratz.github.io/SketchyBar/config/items
        defaults=(
            updates=when_shown
            icon.font="$FONT:Bold:14.0"
            icon.color=$ICON_COLOR
            icon.padding_left=$PADDINGS
            icon.padding_right=$PADDINGS
            label.font="$FONT:Semibold:13.0"
            label.color=$LABEL_COLOR
            label.padding_left=$PADDINGS
            label.padding_right=$PADDINGS
            padding_right=$PADDINGS
            padding_left=$PADDINGS
            background.height=30
            background.corner_radius=9
            popup.background.border_width=2
            popup.background.corner_radius=9
            popup.background.border_color=$POPUP_BORDER_COLOR
            popup.background.color=$POPUP_BACKGROUND_COLOR
            popup.blur_radius=20
            popup.background.shadow.drawing=on
        )

        sketchybar --default "''${defaults[@]}"

        # Left
        source "$ITEM_DIR/apple.sh"
        source "$ITEM_DIR/spaces.sh"
        source "$ITEM_DIR/front_app.sh"

        # Center
        source "$ITEM_DIR/spotify.sh"

        # Right
        source "$ITEM_DIR/calendar.sh"
        source "$ITEM_DIR/brew.sh"
        source "$ITEM_DIR/github.sh"
        source "$ITEM_DIR/battery.sh"
        source "$ITEM_DIR/volume.sh"
        source "$ITEM_DIR/cpu.sh"

        # Forcing all item scripts to run (never do this outside of sketchybarrc)
        sketchybar --update

        echo "sketchybar configuation loaded.."
      '';
    };
  };
}
