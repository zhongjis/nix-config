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
    "GBM_BACKEND,nvidia-drm"
    "LIBVA_DRIVER_NAME,nvidia"
    "SDL_VIDEODRIVER,wayland"
    "WLR_DRM_NO_ATOMIC,1"
    # "__GL_VRR_ALLOWED,1"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "__NV_PRIME_RENDER_OFFLOAD,1"
    "__VK_LAYER_NV_optimus,NVIDIA_only"

    # FOR VM and POSSIBLY NVIDIA
    "WLR_RENDERER_ALLOW_SOFTWARE,1"

    # nvidia firefox (for hardware acceleration on FF)?
    # check this post https://github.com/elFarto/nvidia-vaapi-driver#configuration
    "MOZ_DISABLE_RDD_SANDBOX,1"
    "EGL_PLATFORM,wayland"

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
