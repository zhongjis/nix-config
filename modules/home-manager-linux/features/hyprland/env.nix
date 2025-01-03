{...}: {
  #############################
  ### ENVIRONMENT VARIABLES ###
  #############################

  # See https://wiki.hyprland.org/Configuring/Environment-variables/
  wayland.windowManager.hyprland.settings.env = [
    # CURSOR
    "XCURSOR_SIZE,24"
    "HYPRCURSOR_SIZE,24"

    # GSYNC
    "__GL_GSYNC_ALLOWED,1"
    "__GL_VRR_ALLOWED,0"

    # NVIDIA https://wiki.hyprland.org/Nvidia/
    # "LIBVA_DRIVER_NAME,nvidia"
    # "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    # "__GL_VRR_ALLOWED,1"
    # "WLR_DRM_NO_ATOMIC,1"

    # XDG Desktop Portal
    "XDG_CURRENT_DESKTOP,Hyprland"
    "XDG_SESSION_TYPE,wayland"
    "XDG_SESSION_DESKTOP,Hyprland"

    # QT
    "QT_QPA_PLATFORM,wayland;xcb"
    "QT_QPA_PLATFORMTHEME,qt6ct"
    "QT_QPA_PLATFORMTHEME,qt5ct"
    "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
    "QT_AUTO_SCREEN_SCALE_FACTOR,1"

    # ?
    "MOZ_ENABLE_WAYLAND,1"

    # GDK
    "GDK_SCALE,1"

    # Toolkit Backend
    "GDK_BACKEND,wayland,x11,*"
    "CLUTTER_BACKEND,wayland"

    # Toolkit Backend
    "GDK_BACKEND,wayland,x11,*"
    "CLUTTER_BACKEND,wayland"
  ];
}
