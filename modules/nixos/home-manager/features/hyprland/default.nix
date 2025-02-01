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

  home.packages = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
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
            # col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
            # col.inactive_border = rgba(595959aa)
            col.active_border = rgba(${base0E}ff) rgba(${base09}ff) 60deg
            col.inactive_border = rgba(${base00}ff)

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
              # color = 0x66000000 # managed by stylix
            }
        }

        # https://wiki.hyprland.org/Configuring/Variables/#animations
        animations {
            enabled = true
            # Animation curves

            bezier = linear, 0, 0, 1, 1
            bezier = md3_standard, 0.2, 0, 0, 1
            bezier = md3_decel, 0.05, 0.7, 0.1, 1
            bezier = md3_accel, 0.3, 0, 0.8, 0.15
            bezier = overshot, 0.05, 0.9, 0.1, 1.1
            bezier = crazyshot, 0.1, 1.5, 0.76, 0.92
            bezier = hyprnostretch, 0.05, 0.9, 0.1, 1.0
            bezier = menu_decel, 0.1, 1, 0, 1
            bezier = menu_accel, 0.38, 0.04, 1, 0.07
            bezier = easeInOutCirc, 0.85, 0, 0.15, 1
            bezier = easeOutCirc, 0, 0.55, 0.45, 1
            bezier = easeOutExpo, 0.16, 1, 0.3, 1
            bezier = softAcDecel, 0.26, 0.26, 0.15, 1
            bezier = md2, 0.4, 0, 0.2, 1 # use with .2s duration
            # Animation configs
            animation = windows, 1, 3, md3_decel, popin 60%
            animation = windowsIn, 1, 3, md3_decel, popin 60%
            animation = windowsOut, 1, 3, md3_accel, popin 60%
            animation = border, 1, 10, default
            animation = fade, 1, 3, md3_decel
            # animation = layers, 1, 2, md3_decel, slide
            animation = layersIn, 1, 3, menu_decel, slide
            animation = layersOut, 1, 1.6, menu_accel
            animation = fadeLayersIn, 1, 2, menu_decel
            animation = fadeLayersOut, 1, 4.5, menu_accel
            animation = workspaces, 1, 7, menu_decel, slide
            # animation = workspaces, 1, 2.5, softAcDecel, slide
            # animation = workspaces, 1, 7, menu_decel, slidefade 15%
            # animation = specialWorkspace, 1, 3, md3_decel, slidefadevert 15%
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

        windowrulev2 = workspace special:default,class:^(vesktop)$

        windowrulev2 = workspace name:spotify,class:^(spotify)$

        windowrulev2 = workspace name:obsidian,class:^(obsidian)$

        windowrulev2 = workspace name:gaming,class:^(steam)$
        windowrulev2 = workspace name:gaming,class:^(heroic)$
        windowrulev2 = workspace name:gaming,class:^(com.usebottles.bottles)$
        windowrulev2 = workspace name:gaming,class:^(steam_proton)$
        windowrulev2 = workspace name:gaming,class:^(gamescope)$

        windowrulev2 = workspace name:zen,class:^(zen)$

        # Pavucontrol floating
        windowrulev2 = float,class:(.*org.pulseaudio.pavucontrol.*)
        windowrulev2 = size 900 800,class:(.*org.pulseaudio.pavucontrol.*)
        windowrulev2 = center,class:(.*org.pulseaudio.pavucontrol.*)
        windowrulev2 = pin,class:(.*org.pulseaudio.pavucontrol.*)

        # hide xwaylandvideobridge, more detial see
        # https://wiki.hyprland.org/Useful-Utilities/Screen-Sharing/#xwayland
        windowrulev2 = opacity 0.0 override, class:^(xwaylandvideobridge)$
        windowrulev2 = noanim, class:^(xwaylandvideobridge)$
        windowrulev2 = noinitialfocus, class:^(xwaylandvideobridge)$
        windowrulev2 = maxsize 1 1, class:^(xwaylandvideobridge)$
        windowrulev2 = noblur, class:^(xwaylandvideobridge)$
        windowrulev2 = nofocus, class:^(xwaylandvideobridge)$

        # hope to fix some steam focus issue
        # NOTE: https://www.reddit.com/r/hyprland/comments/19c53ub/steam_on_hyprland_is_extremely_wonky/
        windowrulev2 = stayfocused, title:^()$,class:^(steam)$
        windowrulev2 = minsize 1 1, title:^()$,class:^(steam)$

        # for fcitx5
        # reference: https://discourse.nixos.org/t/pinyin-input-method-in-hyprland-wayland-for-simplified-chinese/49186
        windowrule = pseudo, fcitx
        exec-once=fcitx5 -d -r
        exec-once=fcitx5-remote -r

        cursor {
            no_hardware_cursors = true
        }
      '';
  };
}
