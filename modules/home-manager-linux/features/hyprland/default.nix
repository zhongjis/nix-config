{
  pkgs,
  config,
  ...
}: let
  uptime-sh = pkgs.writeShellScript "uptime-nixos" (builtins.readFile ./scripts/uptime-nixos.sh);
in {
  myHomeManagerLinux.rofi.enable = true;
  myHomeManagerLinux.swaync.enable = true;
  myHomeManagerLinux.waybar.enable = true;
  myHomeManagerLinux.wlogout.enable = true;

  # hyprland
  xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;

  home.pointerCursor = {
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  home.packages = [
    pkgs.nordic
    pkgs.arc-icon-theme
    pkgs.lxappearance
  ];

  home.file.".gtkrc-2.0" = {
    text = ''
      gtk-theme-name="Nordic-darker"
      gtk-icon-theme-name="Arc"
      gtk-font-name="Iosevka 11"
      gtk-cursor-theme-size=0
      gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
      gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
      gtk-button-images=0
      gtk-menu-images=0
      gtk-enable-event-sounds=1
      gtk-enable-input-feedback-sounds=1
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintmedium"
    '';
  };

  home.file.".config/gtk-2.0/gtkfilechooser.ini" = {
    text = ''
      [Filechooser Settings]
      LocationMode=path-bar
      ShowHidden=false
      ShowSizeColumn=true
      GeometryX=442
      GeometryY=212
      GeometryWidth=1036
      GeometryHeight=609
      SortColumn=name
      SortOrder=ascending
      StartupMode=recent
    '';
  };

  home.file.".config/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-theme-name=Nordic-darker
      gtk-icon-theme-name=Arc
      gtk-font-name=Iosevka 11
      gtk-cursor-theme-size=0
      gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
      gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
      gtk-button-images=0
      gtk-menu-images=0
      gtk-enable-event-sounds=1
      gtk-enable-input-feedback-sounds=1
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle=hintmedium
    '';
  };

  # hyprlock
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      $background = rgb(070B11)
      $foreground = rgb(EFF2F5)
      $color0 = rgb(070B11)
      $color1 = rgb(19293E)
      $color2 = rgb(1C2C40)
      $color3 = rgb(4B4C5E)
      $color4 = rgb(4F4E60)
      $color5 = rgb(547191)
      $color6 = rgb(9DA4AA)
      $color7 = rgb(E0E5E8)
      $color8 = rgb(9DA0A2)
      $color9 = rgb(213753)
      $color10 = rgb(263A56)
      $color11 = rgb(65657D)
      $color12 = rgb(696880)
      $color13 = rgb(7096C1)
      $color14 = rgb(D2DBE2)
      $color15 = rgb(E0E5E8)

      ${builtins.readFile ./hyprlock.conf}

      # Uptime
      label {
          monitor =
          text = cmd[update:60000] echo "<b> "$(uptime -p || ${uptime-sh})" </b>"
          color = rgb(184, 192, 224)
          font_size = 11
          font_family = JetBrains Mono Nerd Font 10
          position = 0, -1000
          halign = center
          valign = top
      }
    '';
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # runs hyprlock if it is not already running (this is always run when "loginctl lock-session" is called)
        before_sleep_cmd = "loginctl lock-session"; # ensures that the session is locked before going to sleep
        after_sleep_cmd = "hyprctl dispatch dpms on"; # turn off screen after sleep (not strictly necessary, but just in case)
        ignore_dbus_inhibit = false; # whether to ignore dbus-sent idle-inhibit requests (used by e.g. firefox or steam)
      };

      listener = [
        {
          timeout = 540; # 9 min
          on-timeout = "notify-send \"You are idle!\""; # command to run when timeout has passed
          on-resume = "notify-send \"Welcome back!\""; # command to run when activity is detected after timeout has fired.
        }

        {
          timeout = 600; # 10min
          on-timeout = "loginctl lock-session"; # command to run when timeout has passed
        }
      ];
    };
  };

  xdg.configFile."wallpapers".source = ./wallpapers;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = "${config.home.homeDirectory}/.config/wallpapers/1330031.jpeg";
      wallpaper = "monitor,contain:${config.home.homeDirectory}/.config/wallpapers/1330031.jpeg";
    };
  };
}
