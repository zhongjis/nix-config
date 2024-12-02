{config, ...}: let
in {
  imports = [
    ./autostart.nix
    ./env.nix
  ];
  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = with config.lib.stylix.colors;
    /*
    hyprlang
    */
      ''
        ################
        ### MONITORS ###
        ################

        # See https://wiki.hyprland.org/Configuring/Monitors/
        monitor=,preffered,auto,auto
        monitor=desc:Thermotrex Corporation TL140BDXP02-0,2560x1440@165.00Hz,0x0,1.25
        # monitor=desc:Thermotrex Corporation TL140BDXP02-0, disable
        monitor=desc:LG Electronics LG ULTRAGEAR 009NTDV4B698,3440x1440@143.92Hz,2560x0,1.0
        monitor=desc:Dell Inc. DELL P2419H 78NFR63,1920x1080@60Hz,6000x0,1.0,transform,1
        # monitor=desc:Dell Inc. DELL P2419H 78NFR63, disable

        ###################
        ### MY PROGRAMS ###
        ###################

        # See https://wiki.hyprland.org/Configuring/Keywords/

        # Set programs that you use
        $terminal = kitty
        $fileManager = kitty --title yazi sh -c 'yazi'
        $menu = rofi-toggle

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
            allow_tearing = false

            layout = dwindle
        }

        # https://wiki.hyprland.org/Configuring/Variables/#decoration
        decoration {
            rounding = 10
            active_opacity = 1.0
            inactive_opacity = 1.0
            fullscreen_opacity = 1.0

            blur {
                enabled = true
                size = 6
                passes = 2
                new_optimizations = on
                ignore_opacity = true
                xray = true
                # blurls = waybar
            }

            shadow {
                enabled = true
                range = 30
                render_power = 3
              # color = 0x66000000 # managed by stylix
            }
        }

        # https://wiki.hyprland.org/Configuring/Variables/#animations
        animations {
            enabled = true
            # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
            bezier = myBezier, 0.25, 0.9, 0.1, 1.02
            animation = windows, 1, 7, myBezier
            animation = windowsOut, 1, 7, default, popin 80%
            animation = border, 1, 10, default
            animation = borderangle, 1, 8, default
            animation = fade, 1, 7, default
            animation = workspaces, 1, 6, default
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
            kb_layout = us
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


        ####################
        ### KEYBINDINGSS ###
        ####################

        # See https://wiki.hyprland.org/Configuring/Keywords/
        $mainMod = ALT

        # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
        bind = $mainMod, T, exec, $terminal
        bind = SUPER, Q, killactive,
        # bind = $mainMod, M, exit,
        bind = $mainMod, E, exec, $fileManager
        bind = $mainMod, V, togglefloating,
        bind = SUPER, Space, exec, $menu
        # bind = $mainMod, P, pseudo, # dwindle
        # bind = $mainMod, J, togglesplit, # dwindle
        bind = $mainMod, RETURN, fullscreen, 1
        bind = $mainMod SHIFT, RETURN, fullscreen

        # Move focus with mainMod + arrow keys
        bind = $mainMod, L, movefocus, r
        bind = $mainMod, H, movefocus, l
        bind = $mainMod, K, movefocus, u
        bind = $mainMod, J, movefocus, d

        # Switch workspaces with mainMod + [0-9]
        bind = $mainMod, 1, workspace, 1
        bind = $mainMod, 2, workspace, 2
        bind = $mainMod, 3, workspace, 3
        bind = $mainMod, 4, workspace, 4
        bind = $mainMod, 5, workspace, 5
        bind = $mainMod, 6, workspace, 6
        bind = $mainMod, O, workspace, 7
        bind = $mainMod, P, workspace, 8
        bind = $mainMod, G, workspace, 9
        bind = $mainMod, Z, workspace, 10

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        bind = $mainMod SHIFT, 1, movetoworkspace, 1
        bind = $mainMod SHIFT, 2, movetoworkspace, 2
        bind = $mainMod SHIFT, 3, movetoworkspace, 3
        bind = $mainMod SHIFT, 4, movetoworkspace, 4
        bind = $mainMod SHIFT, 5, movetoworkspace, 5
        bind = $mainMod SHIFT, 6, movetoworkspace, 6
        bind = $mainMod SHIFT, O, movetoworkspace, 7
        bind = $mainMod SHIFT, P, movetoworkspace, 8
        bind = $mainMod SHIFT, G, movetoworkspace, 9
        bind = $mainMod SHIFT, Z, movetoworkspace, 10

        # Example special workspace (scratchpad)
        bind = $mainMod, S, togglespecialworkspace, magic
        bind = $mainMod SHIFT, S, movetoworkspace, special:magic

        # Scroll through existing workspaces with mainMod + scroll
        # bind = $mainMod, mouse_down, workspace, e+1
        # bind = $mainMod, mouse_up, workspace, e-1

        # Move/resize windows with mainMod + LMB/RMB and dragging
        bindm = $mainMod SHIFT, mouse:272, movewindow
        bindm = $mainMod SHIFT, mouse:273, resizewindow


        ##############################
        ### WINDOWS AND WORKSPACES ###
        ##############################

        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

        # Example windowrule v1
        # windowrule = float, ^(kitty)$

        windowrulev2 = workspace 1,class:^(spotify)$
        windowrulev2 = workspace special:magic,class:^(discord)$
        windowrulev2 = workspace 7,class:^(obsidian)$
        windowrulev2 = workspace 9,class:^(steam)$
        windowrulev2 = workspace 10,class:^(zen-alpha)$
        # windowrulev2 = float,center,size 40% 60%,class:kitty,title:btop
        # windowrulev2 = float,center,size 40% 60%,class:kitty,title:nvtop
        # windowrulev2 = float,center,size 40% 60%,class:kitty,title:nmtui
        # windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.

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
        cursor {
            no_hardware_cursors = true
        }
      '';
  };
}
