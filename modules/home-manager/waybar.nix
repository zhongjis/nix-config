{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
        mainBar = {
            layer = "top";
            position = "top";
            height = 32;
            spacing = 4;
            modules-left = [ 
                "wlr/taskbar" 
                "hyprland/window"
            ];
            modules-center = [
              "hyprland/workspaces"
            ];
            modules-right = [
                "idle_inhibitor"
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

            "hyprland/workspaces" = {
                on-click = "activate";
                active-only = false;
                all-outputs = true;
                format = "{}";
                format-icons = {
                    urgent = "";
                    active = "";
                    default = "";
                };
                persistent-workspaces = {
                    "*" = 5;
                };
            };

            "wlr/taskbar" = {
                format = "{icon}";
                icon-size = 18;
                tooltip-format = "{title}";
                on-click = "activate";
                on-click-middle = "close";
                ignore-list = [];
                app_ids-mapping = {};
                rewirte = {
                    "Firefox Web Browser" = "Firefox";
                };
            };

            "hyprland/window" = {
                rewrite = {
                    "(.*) - Brave" = "$1";
                    "(.*) - Chromium" = "$1";
                    "(.*) - Brave Search" = "$1";
                    "(.*) - Outlook" = "$1";
                    "(.*) Microsoft Teams" = "$1";
                };
                separate-outputs = true;
            };

            "idle_inhibitor" = {
                format = "{icon}";
                format-icons = {
                    activated = "";
                    deactivated = "";
                };
            };

            "clock"= {
                # "timezone"= "America/New_York";
                tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                format-alt = "{:%Y-%m-%d}";
            };

            "cpu"= {
                format = "{usage}% ";
                tooltip = false;
            };

            "memory"= {
                format = "{}% ";
            };

            "temperature"= {
                # "thermal-zone"= 2;
                # "hwmon-path"= "/sys/class/hwmon/hwmon2/temp1_input";
                critical-threshold = 80;
                # "format-critical"= "{temperatureC}°C {icon}";
                format= "{temperatureC}°C {icon}";
                format-icons = ["" "" ""];
            };

            "backlight"= {
                # "device"= "acpi_video1";
                format = "{percent}% {icon}";
                format-icons = ["" "" "" "" "" "" "" "" ""];
            };

            "battery"= {
                states= {
                    # "good"= 95;
                    warning = 30;
                    critical = 15;
                };
                format = "{capacity}% {icon}";
                format-full = "{capacity}% {icon}";
                format-charging = "{capacity}% ";
                format-plugged = "{capacity}% ";
                format-alt = "{time} {icon}";
                # format-good = ""; # An empty format will hide the module
                # format-full = "";
                format-icons= ["" "" "" "" ""];
            };

            "network" = {
                format = "{ifname}";
                format-wifi = "   {signalStrength}%";
                format-ethernet = "  {ifname}";
                format-disconnected = "Disconnected";
                tooltip-format = " {ifname} via {gwaddri}";
                tooltip-format-wifi = "  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
                tooltip-format-ethernet = " {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}";
                tooltip-format-disconnected = "Disconnected";
                max-length = 50;
                # on-click = "~/dotfiles/.settings/networkmanager.sh";
            };

            "pulseaudio" = {
                scroll-step = 1;
                format = "{icon} {volume}%";
                format-bluetooth = "{volume}% {icon} {format_source}";
                format-bluetooth-muted = " {icon} {format_source}";
                format-muted = " {format_source}";
                format-source = "{volume}% ";
                format-source-muted = "";
                format-icons = {
                    headphone = "";
                    hands-free = "";
                    headset = "";
                    phone = "";
                    portable = "";
                    car = "";
                    default = ["" " " " "];
                };
                "on-click" = "pavucontrol";
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
    };
  };

  home.packages = with pkgs; [
    rofi
  ];
}
