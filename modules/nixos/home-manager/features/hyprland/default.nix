{
  config,
  lib,
  pkgs,
  ...
}: let
  workspaceToMonitorSetup =
    lib.mapAttrsToList
    (id: workspace: "workspace = ${id},monitor:${workspace.monitorId}")
    config.myHomeManager.hyprland.workspaces;
in {
  imports = [
    ./startup.nix
    ./monitors.nix
    ./env.nix
    ./keymaps.nix
  ];

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    # NOTE: below two are defined in nixos module
    package = null;
    portalPackage = null;
    # See https://wiki.hyprland.org/Configuring/Monitors/
    settings.monitor =
      lib.mapAttrsToList
      (
        name: m: let
          resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
          position = "${toString m.x}x${toString m.y}";
          scale = "${toString m.scale}";
          transform =
            if m.rotate == 0
            then ""
            else "transform,${toString m.rotate}";
        in "${name},${
          if m.enabled
          then "${resolution},${position},${scale},${transform}"
          else "disable"
        }"
      )
      (config.myHomeManager.hyprland.monitors);
    extraConfig = with config.lib.stylix.colors;
    /*
    hyprlang
    */
      ''
        #####################
        ### LOOK AND FEEL ###
        #####################

        # Refer to https://wiki.hyprland.org/Configuring/Variables/

        # https://wiki.hyprland.org/Configuring/Variables/#general
        general {
            gaps_in = 5
            gaps_out = 10

            border_size = 2

            # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
            # NOTE: below block managed by stylix
            # col.active_border = rgba(${base0E}ff) rgba(${base09}ff) 60deg
            # col.inactive_border = rgba(${base00}ff)

            # Set to true enable resizing windows by clicking and dragging on borders and gaps
            resize_on_border = false

            # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
            allow_tearing = true

            layout = maste
        }

        # https://wiki.hyprland.org/Configuring/Variables/#decoration
        decoration {
            rounding = 10
            active_opacity = 1.0
            inactive_opacity = 1.0
            fullscreen_opacity = 1.0

            blur {
                enabled = false # for laptop battery
            }

            shadow {
                enabled = false # for laptop battery
                range = 30
                render_power = 3
                # NOTE: below block managed by stylix
                # color = 0x66000000 # managed by stylix
            }
        }

        # https://wiki.hyprland.org/Configuring/Variables/#animations
        animations {
            enabled = true
            bezier = linear, 0, 0, 1, 1
            bezier = md3_standard, 0.2, 0, 0, 1
            bezier = md3_decel, 0.05, 0.7, 0.1, 1
            bezier = md3_accel, 0.3, 0, 0.8, 0.15
            bezier = overshot, 0.05, 0.9, 0.1, 1.1
            bezier = crazyshot, 0.1, 1.5, 0.76, 0.92
            bezier = hyprnostretch, 0.05, 0.9, 0.1, 1.0
            bezier = fluent_decel, 0.1, 1, 0, 1
            bezier = easeInOutCirc, 0.85, 0, 0.15, 1
            bezier = easeOutCirc, 0, 0.55, 0.45, 1
            bezier = easeOutExpo, 0.16, 1, 0.3, 1
            animation = windows, 1, 3, md3_decel, popin 60%
            animation = border, 1, 10, default
            animation = fade, 1, 2.5, md3_decel
            animation = workspaces, 1, 3.5, easeOutExpo, slide
            animation = specialWorkspace, 1, 3, md3_decel, slidevert
        }

        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        dwindle {
            pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true # You probably want this
        }

        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        master {
            new_status = master
        }

        # https://wiki.hyprland.org/Configuring/Variables/#misc
        misc {
            force_default_wallpaper = 0
        }


        #############
        ### INPUT ###
        #############

        # https://wiki.hyprland.org/Configuring/Variables/#input
        input {
            kb_layout = us,cn
            kb_variant =
            kb_model =
            kb_options =
            kb_rules =

            follow_mouse = 1

            sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

            touchpad {
                natural_scroll = true
            }
        }

        # https://wiki.hyprland.org/Configuring/Variables/#gestures
        gestures {
            workspace_swipe = false
        }

        # Example per-device config
        # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
        device {
            name = epic-mouse-v1
            sensitivity = -0.5
        }

        ##############################
        ### WINDOWS AND WORKSPACES ###
        ##############################

        ${lib.concatLines workspaceToMonitorSetup}

        windowrule = workspace special:default,class:^(vesktop)$

        windowrule = workspace name:spotify,class:^(spotify)$

        windowrule = workspace name:obsidian,class:^(obsidian)$

        windowrule = workspace name:gaming,class:^(steam)$
        windowrule = workspace name:gaming,class:^(heroic)$
        windowrule = workspace name:gaming,class:^(com.usebottles.bottles)$
        windowrule = workspace name:gaming,class:^(steam_proton)$
        windowrule = workspace name:gaming,class:^(gamescope)$

        windowrule = workspace name:zen,class:^(vivaldi-stable)$

        # Pavucontrol floating
        windowrule = float,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = size 900 800,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = center,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = pin,class:(.*org.pulseaudio.pavucontrol.*)

        # hide xwaylandvideobridge, more detial see
        # https://wiki.hyprland.org/Useful-Utilities/Screen-Sharing/#xwayland
        windowrule = opacity 0.0 override, class:^(xwaylandvideobridge)$
        windowrule = noanim, class:^(xwaylandvideobridge)$
        windowrule = noinitialfocus, class:^(xwaylandvideobridge)$
        windowrule = maxsize 1 1, class:^(xwaylandvideobridge)$
        windowrule = noblur, class:^(xwaylandvideobridge)$
        windowrule = nofocus, class:^(xwaylandvideobridge)$

        # hope to fix some steam focus issue
        # NOTE: https://www.reddit.com/r/hyprland/comments/19c53ub/steam_on_hyprland_is_extremely_wonky/
        windowrule = stayfocused, title:^()$,class:^(steam)$
        windowrule = minsize 1 1, title:^()$,class:^(steam)$

        # for fcitx5
        # reference: https://discourse.nixos.org/t/pinyin-input-method-in-hyprland-wayland-for-simplified-chinese/49186
        windowrule = pseudo, title:^()$,class:^(fcitx)$
        exec-once=fcitx5 -d -r
        exec-once=fcitx5-remote -r

        # Browser Picture in Picture
        windowrule = float, title:^(Picture-in-Picture)$
        windowrule = pin, title:^(Picture-in-Picture)$
        windowrule = move 69.5% 4%, title:^(Picture-in-Picture)$

        cursor {
            no_hardware_cursors = true
        }
      '';
  };
}
