{...}: {
  wayland.windowManager.hyprland.settings = {
    #####################
    ### LOOK AND FEEL ###
    #####################

    # Refer to https://wiki.hyprland.org/Configuring/Variables/

    # https://wiki.hyprland.org/Configuring/Variables/#general
    general = {
      gaps_in = 2;
      gaps_out = 5;

      border_size = 2;

      # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
      # NOTE: below block managed by stylix
      # col.active_border = rgba(${base0E}ff) rgba(${base09}ff) 60deg
      # col.inactive_border = rgba(${base00}ff)

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false;

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = true;

      layout = "dwindle";
    };

    # https://wiki.hyprland.org/Configuring/Variables/#decoration
    decoration = {
      rounding = 0;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      fullscreen_opacity = 1.0;

      blur = {
        enabled = false; # for laptop battery
      };

      shadow = {
        enabled = false; # for laptop battery
        range = 30;
        render_power = 3;
        # NOTE: below block managed by stylix
        # color = 0x66000000 # managed by stylix
      };
    };
    # https://wiki.hyprland.org/Configuring/Variables/#animations
    animations = {
      enabled = false;
      bezier = [
        "linear, 0, 0, 1, 1"
        "md3_standard, 0.2, 0, 0, 1"
        "md3_decel, 0.05, 0.7, 0.1, 1"
        "md3_accel, 0.3, 0, 0.8, 0.15"
        "overshot, 0.05, 0.9, 0.1, 1.1"
        "crazyshot, 0.1, 1.5, 0.76, 0.92"
        "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
        "fluent_decel, 0.1, 1, 0, 1"
        "easeInOutCirc, 0.85, 0, 0.15, 1"
        "easeOutCirc, 0, 0.55, 0.45, 1"
        "easeOutExpo, 0.16, 1, 0.3, 1"
      ];
      animation = [
        "windows, 1, 3, md3_decel, popin 60%"
        "border, 1, 10, default"
        "fade, 1, 2.5, md3_decel"
        "workspaces, 1, 3.5, easeOutExpo, slide"
        "specialWorkspace, 1, 3, md3_decel, slidevert"
      ];
    };

    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    dwindle = {
      pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true; # You probably want this
    };

    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    master = {
      new_status = "master";
    };

    # https://wiki.hyprland.org/Configuring/Variables/#misc
    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      initial_workspace_tracking = 1;
      middle_click_paste = false;
    };

    #############
    ### INPUT ###
    #############

    # https://wiki.hyprland.org/Configuring/Variables/#input
    input = {
      kb_layout = "us,cn";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      numlock_by_default = true;
      follow_mouse = 1;
      mouse_refocus = false;

      touchpad = {
        natural_scroll = true;
        scroll_factor = 1.0; # Touchpad scroll factor
      };

      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
    };

    # https://wiki.hyprland.org/Configuring/Variables/#gestures
    gestures = {};

    # Example per-device config
    # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
    device = {
      name = "epic-mouse-v1";
      sensitivity = -0.5;
    };

    cursor = {
      no_hardware_cursors = true;
    };

    debug = {
      full_cm_proto = true;
    };
  };
}
