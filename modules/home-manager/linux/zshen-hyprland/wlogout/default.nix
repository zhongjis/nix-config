{
  lib,
  config,
  ...
}: {
  options = {
    wlogout.enable =
      lib.mkEnableOption "enable wlogout";
  };

  config = lib.mkIf config.wlogout.enable {
    xdg.configFile."wlogout/icons".source = ./icons;

    services.wlogout = {
      enable = true;
      layout = [
        {
          label = "lock";
          action = "$HOME/.config/hypr/scripts/LockScreen.sh";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "logout";
          action = "loginctl kill-session $XDG_SESSION_ID";
          text = "Logout";
          keybind = "e";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "u";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
        }
      ];
      style = ''
        ${builtins.readFile ./style.css}
      '';
    };
  };
}
