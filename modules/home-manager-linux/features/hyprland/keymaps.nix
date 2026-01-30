{
  pkgs,
  lib,
  inputs,
  ...
}: let
  close-application-sh =
    pkgs.writeShellScript "hyprland-close-application"
    (builtins.readFile ./scripts/close-application.sh);
  screenshot-sh =
    pkgs.writeShellScript "hyprland-screenshot"
    (builtins.readFile ./scripts/screenshot.sh);
in {
  home.packages = with pkgs;
    lib.optionals stdenv.isLinux [
      grimblast
    ];

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
    "$wmMod" = "ALT";
    "$cmdMod" = "SUPER";

    bind = [
      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      "$wmMod, T, exec, $terminal"
      "$cmdMod, Q, exec, ${close-application-sh}"
      "$wmMod, E, exec, $fileManager"
      "$wmMod, V, togglefloating,"
      "$cmdMod, Space, exec, $menu"
      "$wmMod, Space, exec, rofi-toggle-cliphist"
      # "$wmMod, P, pseudo," # dwindle
      # "$wmMod, J, togglesplit," # dwindle
      "$wmMod, RETURN, fullscreen, 1"
      "$wmMod SHIFT, RETURN, fullscreen"

      # screenshot
      "$cmdMod SHIFT, 4, exec, ${screenshot-sh}"

      # Move focus with wmMod + arrow keys
      "$wmMod, L, movefocus, r"
      "$wmMod, H, movefocus, l"
      "$wmMod, K, movefocus, u"
      "$wmMod, J, movefocus, d"

      # Switch workspaces with wmMod + [0-9]
      "$wmMod, 1, workspace, 1"
      "$wmMod, 2, workspace, 2"
      "$wmMod, 3, workspace, 3"
      "$wmMod, 4, workspace, 4"
      "$wmMod, 5, workspace, 5"

      "$wmMod, O, workspace, name:obsidian"
      "$wmMod, G, workspace, name:gaming"
      "$wmMod, Z, workspace, name:zen"

      # Move active window to a workspace with wmMod + SHIFT + [0-9]
      "$wmMod SHIFT, 1, movetoworkspace, 1"
      "$wmMod SHIFT, 2, movetoworkspace, 2"
      "$wmMod SHIFT, 3, movetoworkspace, 3"
      "$wmMod SHIFT, 4, movetoworkspace, 4"
      "$wmMod SHIFT, 5, movetoworkspace, 5"

      "$wmMod SHIFT, O, movetoworkspace, name:obsidian"
      "$wmMod SHIFT, G, movetoworkspace, name:gaming"
      "$wmMod SHIFT, Z, movetoworkspace, name:zen"

      # Example special workspace (scratchpad)
      "$wmMod, S, togglespecialworkspace, default"
      "$wmMod SHIFT, S, movetoworkspace, special:default"

      # ALT TAB
      "ALT, Tab, cyclenext"
      "ALT, Tab, bringactivetotop"
    ];
    bindm = [
      # Move/resize windows with wmMod + LMB/RMB and dragging
      "$wmMod SHIFT, mouse:272, movewindow"
      "$wmMod SHIFT, mouse:273, resizewindow"
    ];
  };
}
