{ 
    pkgs, 
    ... 
}:let 
    mainBarConfig = {
        layer = "top";
        position = "top";
        height = 35;
        spacing = 4;
        modules-left = [ 
            "wlr/taskbar" 
            "hyprland/window"
        ];
        modules-center = [
            "hyprland/workspaces"
        ];
        modules-right = [
            "pulseaudio"
            "bluetooth"
            "cpu"
            "memory"
            "disk"
            "temperature"
            "network"
            "battery"
            "clock"
        ];

        "disk" = {
            format = "[DISK:{percentage_used}%]";
        };

        "hyprland/workspaces" = {
            format = "[{id}]";
        };

        "hyprland/window" = {
            format = "[{title}]";
        };

        "clock"= {
            format = "[{:%H:%M %Y-%m-%d}]";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
                on-click-right = "mode";
                format = {
                    months =     "<span color='#ffead3'><b>{}</b></span>";
                    days =       "<span color='#ecc6d9'><b>{}</b></span>";
                    weeks =      "<span color='#99ffdd'><b>W{}</b></span>";
                    weekdays =   "<span color='#ffcc66'><b>{}</b></span>";
                    today =      "<span color='#ff6699'><b><u>{}</u></b></span>";
                };
            };
            actions = {
                on-click-right = "mode";
                on-click-forward = "tz_up";
                on-click-backward = "tz_down";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
            };
        };

        "cpu"= {
            format = "[CPU:{usage}%]";
            tooltip = false;
        };

        "memory"= {
            format = "[MEM:{percentage}%]";
        };

        "temperature"= {
            # "thermal-zone"= 2;
            # "hwmon-path"= "/sys/class/hwmon/hwmon2/temp1_input";
            critical-threshold = 80;
            # "format-critical"= "{temperatureC}°C {icon}";
            format-critical = "[!!{temperatureC}°C!!]";
            format = "[{temperatureC}°C]";
        };

        "backlight"= {
            # "device"= "acpi_video1";
            format = "{percent}% {icon}";
            format-icons = ["" "" "" "" "" "" "" "" ""];
        };

        "battery"= {
            format = "[BAT:{capacity}%]";
            format-charging = "[BAT:{capacity}%+]";
        };

        "network" = {
            format = "{ifname}";
            format-wifi = "[WIFI:{signalStrength}%]";
            format-ethernet = "[ETH:{ifname}]";
            format-disconnected = "[Disconnected]";
            tooltip-format = " {ifname} via {gwaddri}";
            tooltip-format-wifi = "  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
            tooltip-format-ethernet = " {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}";
            max-length = 50;
            # on-click = "~/dotfiles/.settings/networkmanager.sh";
        };

        "pulseaudio" = {
            format = "[VOL:{volume}%]";
            format-muted = "[VOL:MUTE]";
            on-click = "pavucontrol";
        };

        "bluetooth" = {
            format = " {status}";
            format-disabled = "";
            format-off = "";
            interval = 30;
            on-click = "blueman-manager";
            format-no-controller = "";
        };
    };

    css = ''
      ${builtins.readFile ./style.css}
    '';
in {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    });
    settings.mainBar = mainBarConfig;
    style = css;
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "restart-waybar" ''
    ${builtins.readFile ./restart-waybar.sh}
  '')
  ];
}
