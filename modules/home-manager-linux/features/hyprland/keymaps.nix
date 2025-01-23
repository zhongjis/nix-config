{
  pkgs,
  inputs,
  currentSystem,
  ...
}: let
  close-application-sh =
    pkgs.writeShellScript "hyprland-close-application"
    (builtins.readFile ./scripts/close-application.sh);
in {
  home.packages = [
    inputs.hyprswitch.packages.${currentSystem}.default
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
    "$ctrlMod" = "SUPER";
    "$key" = "tab";
    "$reverse" = "grave";

    bind = [
      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      "$wmMod, T, exec, $terminal"
      "$ctrlMod, Q, exec, ${close-application-sh}"
      "$wmMod, E, exec, $fileManager"
      "$wmMod, V, togglefloating,"
      "$ctrlMod, Space, exec, $menu"
      "$wmMod, Space, exec, rofi-toggle-cliphist"
      # "$wmMod, P, pseudo," # dwindle
      # "$wmMod, J, togglesplit," # dwindle
      "$wmMod, RETURN, fullscreen, 1"
      "$wmMod SHIFT, RETURN, fullscreen"

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
      "$wmMod, 6, workspace, 6"
      "$wmMod, O, workspace, 7"
      "$wmMod, P, workspace, 8"
      "$wmMod, G, workspace, 9"
      "$wmMod, Z, workspace, 10"

      # Move active window to a workspace with wmMod + SHIFT + [0-9]
      "$wmMod SHIFT, 1, movetoworkspace, 1"
      "$wmMod SHIFT, 2, movetoworkspace, 2"
      "$wmMod SHIFT, 3, movetoworkspace, 3"
      "$wmMod SHIFT, 4, movetoworkspace, 4"
      "$wmMod SHIFT, 5, movetoworkspace, 5"
      "$wmMod SHIFT, 6, movetoworkspace, 6"
      "$wmMod SHIFT, O, movetoworkspace, 7"
      "$wmMod SHIFT, P, movetoworkspace, 8"
      "$wmMod SHIFT, G, movetoworkspace, 9"
      "$wmMod SHIFT, Z, movetoworkspace, 10"

      # Example special workspace (scratchpad)
      "$wmMod, S, togglespecialworkspace, magic"
      "$wmMod SHIFT, S, movetoworkspace, special:magic"

      # Hyprswitch
      "$wmMod, $key, exec, hyprswitch gui --mod-key $mod --key $key --close mod-key-release --reverse-key=key=$reverse && hyprswitch dispatch"
      "$wmMod $reverse, $key, exec, hyprswitch gui --mod-key $mod --key $key --close mod-key-release --reverse-key=key=$reverse && hyprswitch dispatch -r"
    ];
    bindm = [
      # Move/resize windows with wmMod + LMB/RMB and dragging
      "$wmMod SHIFT, mouse:272, movewindow"
      "$wmMod SHIFT, mouse:273, resizewindow"
    ];
  };
}
