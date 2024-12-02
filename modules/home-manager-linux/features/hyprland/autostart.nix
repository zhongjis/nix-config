{pkgs, ...}: let
in {
  #################
  ### AUTOSTART ###
  #################

  # Autostart necessary processes (like notifications daemons, status bars, etc.)
  # Or execute your favorite apps at launch like this:
  wayland.windowManager.hyprland.settings.exec-once = [
    "waybar"
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "solaar --window=hide"
  ];
}
