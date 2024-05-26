{
  lib,
  config,
  pkgs,
  ...
}: let
  colors = ./config/colors.sh;
  icons = ./config/icons.sh;
  item_dir = ./config/items;
  plugin_dir = ./config/plugins;
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
        #!/usr/bin/env sh

        source "${colors}" # Loads all defined colors
        source "${icons}" # Loads all defined icons

        ITEM_DIR="${item_dir}" # Directory where the items are configured
        PLUGIN_DIR="${plugin_dir}" # Directory where all the plugin scripts are stored

        FONT="SF Pro" # Needs to have Regular, Bold, Semibold, Heavy and Black variants
        SPACE_CLICK_SCRIPT="yabai -m space --focus \$SID 2>/dev/null" # The script that is run for clicking on space components

        PADDINGS=3 # All paddings use this value (icon, label, background and bar paddings)

        POPUP_BORDER_WIDTH=2
        POPUP_CORNER_RADIUS=11

        SHADOW=on

        # Setting up the general bar appearance and default values
        sketchybar --bar     height=39                                           \
                             corner_radius=9                                     \
                             border_width=0                                      \
                             margin=10                                           \
                             blur_radius=50                                      \
                             position=top                                        \
                             padding_left=10                                     \
                             padding_right=10                                    \
                             color=$BAR_COLOR                                    \
                             topmost=off                                         \
                             sticky=on                                           \
                             font_smoothing=off                                  \
                             y_offset=10                                         \
                             shadow=$SHADOW                                      \
                             notch_width=200                                     \
                                                                                 \
                   --default drawing=on                                          \
                             updates=when_shown                                  \
                             label.font="$FONT:Semibold:13.0"                    \
                             icon.font="$FONT:Bold:14.0"                         \
                             icon.color=$ICON_COLOR                              \
                             label.color=$LABEL_COLOR                            \
                             icon.padding_left=$PADDINGS                         \
                             icon.padding_right=$PADDINGS                        \
                             label.padding_left=$PADDINGS                        \
                             label.padding_right=$PADDINGS                       \
                             background.padding_right=$PADDINGS                  \
                             background.padding_left=$PADDINGS                   \
                             popup.background.border_width=$POPUP_BORDER_WIDTH   \
                             popup.background.corner_radius=$POPUP_CORNER_RADIUS \
                             popup.background.border_color=$POPUP_BORDER_COLOR   \
                             popup.background.color=$POPUP_BACKGROUND_COLOR      \
                             popup.background.shadow.drawing=$SHADOW

        # Left
        source "$ITEM_DIR/apple.sh"
        source "$ITEM_DIR/spaces.sh"
        source "$ITEM_DIR/front_app.sh"

        # Right
        source "$ITEM_DIR/github.sh"
        source "$ITEM_DIR/mail.sh"
        source "$ITEM_DIR/calendar.sh"
        source "$ITEM_DIR/cpu.sh"

        ############## FINALIZING THE SETUP ##############
        sketchybar --update

        echo "sketchybar configuation loaded.."
      '';
    };
  };
}
