{pkgs, ...}: {
  #############################
  ### ENVIRONMENT VARIABLES ###
  #############################

  # for theming
  xdg.configFile."uwsm/env".text = ''
    # CURSOR
    export XCURSOR_SIZE = 24
    export HYPRCURSOR_THEME = catppuccin-cursors-mochaDark
    export HYPRCURSOR_SIZE = 24

    # XDG Desktop Portal
    export XDG_CURRENT_DESKTOP = Hyprland
    export XDG_SESSION_TYPE = wayland
    export XDG_SESSION_DESKTOP = Hyprland

    # GSYNC
    export __GL_GSYNC_ALLOWED = 1
    export __GL_VRR_ALLOWED = 0

    # NVIDIA https://wiki.hyprland.org/Nvidia/
    # export LIBVA_DRIVER_NAME = nvidia
    # export __GLX_VENDOR_LIBRARY_NAME = nvidia
    # export __GL_VRR_ALLOWED = 1
    # export WLR_DRM_NO_ATOMIC = 1

    # QT
    export QT_QPA_PLATFORM = wayland;xcb
    export QT_QPA_PLATFORMTHEME = qt6ct
    export QT_QPA_PLATFORMTHEME = qt5ct
    export QT_WAYLAND_DISABLE_WINDOWDECORATION = 1
    export QT_AUTO_SCREEN_SCALE_FACTOR = 1

    # Mozilla
    export MOZ_ENABLE_WAYLAND = 1

    # GDK
    export GDK_SCALE = 1

    # Toolkit Backend
    export GDK_BACKEND = wayland,x11,*
    export CLUTTER_BACKEND = wayland

    # Toolkit Backend
    export GDK_BACKEND = wayland,x11,*
    export CLUTTER_BACKEND = wayland
  '';

  # others?
  xdg.configFile."uwsm/env-hyprland".text = ''
    # Hyprland-specific variables
    # (Add any HYPR* or AQ_* variables here when needed)
  '';

  # See https://wiki.hyprland.org/Configuring/Environment-variables/
  wayland.windowManager.hyprland.settings.env = [];
}
