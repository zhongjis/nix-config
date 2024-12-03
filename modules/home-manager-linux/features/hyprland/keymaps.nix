{...}: {
  ####################
  ### KEYBINDINGSS ###
  ####################
  wayland.windowManager.hyprland.settings = {
    ###################
    ### MY PROGRAMS ###
    ###################

    # See https://wiki.hyprland.org/Configuring/Keywords/

    # Set programs that you use
    "$terminal" = "kitty";
    "$fileManager" = "kitty --title yazi sh -c 'yazi'";
    "$menu" = "rofi-toggle";

    # See https://wiki.hyprland.org/Configuring/Keywords/
    "$mainMod" = "ALT";
    bind = [
      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      "$mainMod, T, exec, $terminal"
      "SUPER, Q, killactive,"
      # bind = $mainMod, M, exit,
      "$mainMod, E, exec, $fileManager"
      "$mainMod, V, togglefloating,"
      "SUPER, Space, exec, $menu"
      "$mainMod, $mainMod, exec, rofi-toggle-cliphist"
      # "$mainMod, P, pseudo," # dwindle
      # "$mainMod, J, togglesplit," # dwindle
      "$mainMod, RETURN, fullscreen, 1"
      "$mainMod SHIFT, RETURN, fullscreen"

      # Move focus with mainMod + arrow keys
      "$mainMod, L, movefocus, r"
      "$mainMod, H, movefocus, l"
      "$mainMod, K, movefocus, u"
      "$mainMod, J, movefocus, d"

      # Switch workspaces with mainMod + [0-9]
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, O, workspace, 7"
      "$mainMod, P, workspace, 8"
      "$mainMod, G, workspace, 9"
      "$mainMod, Z, workspace, 10"

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, O, movetoworkspace, 7"
      "$mainMod SHIFT, P, movetoworkspace, 8"
      "$mainMod SHIFT, G, movetoworkspace, 9"
      "$mainMod SHIFT, Z, movetoworkspace, 10"

      # Example special workspace (scratchpad)
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"
    ];
    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "$mainMod SHIFT, mouse:272, movewindow"
      "$mainMod SHIFT, mouse:273, resizewindow"
    ];
  };
}
