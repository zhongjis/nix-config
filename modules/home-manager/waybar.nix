{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    # package = "";
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
                # "backlight"
                # "keyboard-state"
                "network"
                "battery"
                "clock"
            ];

            "keyboard-state" = {
                numlock = true;
                capslock = true;
                format = "{name} {icon}";
                format-icons= {
                    locked= "";
                    unlocked= "";
                };
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

            "network"= {
                # interface = "wlp2*"; # (Optional) To force the use of this interface
                format-wifi = "{essid} ({signalStrength}%) ";
                format-ethernet = "{ipaddr}/{cidr} ";
                tooltip-format = "{ifname} via {gwaddr} ";
                format-linked = "{ifname} (No IP) ";
                format-disconnected = "Disconnected ⚠";
                format-alt = "{ifname}: {ipaddr}/{cidr}";
            };

            "pulseaudio"= {
                # scroll-step = 1; # %; can be a float
                format = "{volume}% {icon} {format_source}";
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
                    default = ["" "" ""];
                };
                on-click = "pavucontrol";
            };
        };
    };
  };

  home.packages = with pkgs; [
    rofi
  ];
}
