{...}: let
in {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # runs hyprlock if it is not already running (this is always run when "loginctl lock-session" is called)
        before_sleep_cmd = "loginctl lock-session"; # ensures that the session is locked before going to sleep
        # after_sleep_cmd = "hyprctl dispatch dpms on"; # turn off screen after sleep (not strictly necessary, but just in case)
        # ignore_dbus_inhibit = false; # whether to ignore dbus-sent idle-inhibit requests (used by e.g. firefox or steam)
      };

      listener = [
        {
          timeout = 540; # 9 min - warning
          on-timeout = "notify-send \"You are idle!\""; # command to run when timeout has passed
          on-resume = "notify-send \"Welcome back!\""; # command to run when activity is detected after timeout has fired.
        }

        {
          timeout = 600; # 10min - lock
          on-timeout = "loginctl lock-session"; # command to run when timeout has passed
        }

        {
          timeout = 1800; # 30min - suspend
          on-timeout = "pidof steam || systemctl suspend || loginctl suspend"; # command to run when timeout has passed
        }
      ];
    };
  };
}
