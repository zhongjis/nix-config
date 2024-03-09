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

    style = ''
        @define-color backgroundlight @color11;
        @define-color workspacesbackground1 @color11;
        @define-color bordercolor #FFFFFF;
        @define-color textcolor1 @color11;
        @define-color iconcolor #FFFFFF;

        * {
            font-family: \"Fira Code Nerd Font\", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
            border: none;
            border-radius: 0px;
        }

        window#waybar {
            background-color: rgba(0,0,0,0.8);
            border-bottom: 0px solid #ffffff;
            /* color: #FFFFFF; */
            background: transparent;
            transition-property: background-color;
            transition-duration: .5s;
        }

        /* -----------------------------------------------------
        * Workspaces 
        * ----------------------------------------------------- */

        #workspaces {
            background: @workspacesbackground1;
            margin: 2px 1px 3px 1px;
            padding: 0px 1px;
            border-radius: 15px;
            border: 0px;
            font-weight: bold;
            font-style: normal;
            opacity: 0.8;
            font-size: 16px;
            color: @textcolor1;
        }

        #workspaces button {
            padding: 0px 5px;
            margin: 4px 3px;
            border-radius: 15px;
            border: 0px;
            color: @textcolor1;
            background-color: @workspacesbackground2;
            transition: all 0.3s ease-in-out;
            opacity: 0.4;
        }

        #workspaces button.active {
            color: @textcolor1;
            background: @workspacesbackground2;
            border-radius: 15px;
            min-width: 40px;
            transition: all 0.3s ease-in-out;
            opacity:1.0;
        }

        #workspaces button:hover {
            color: @textcolor1;
            background: @workspacesbackground2;
            border-radius: 15px;
            opacity:0.7;
        }

        /* -----------------------------------------------------
        * Tooltips
        * ----------------------------------------------------- */

        tooltip {
            border-radius: 10px;
            background-color: @backgroundlight;
            opacity:0.8;
            padding:20px;
            margin:0px;
        }

        tooltip label {
            color: @textcolor2;
        }

        /* -----------------------------------------------------
        * Window
        * ----------------------------------------------------- */

        #window {
            background: @backgroundlight;
            margin: 5px 15px 5px 0px;
            padding: 2px 10px 0px 10px;
            border-radius: 12px;
            color:@textcolor2;
            font-size:16px;
            font-weight:normal;
            opacity:0.8;
        }

        window#waybar.empty #window {
            background-color:transparent;
        }

        /* -----------------------------------------------------
        * Taskbar
        * ----------------------------------------------------- */

        #taskbar {
            background: @backgroundlight;
            margin: 3px 15px 3px 0px;
            padding:0px;
            border-radius: 15px;
            font-weight: normal;
            font-style: normal;
            opacity:0.8;
            border: 3px solid @backgroundlight;
        }

        #taskbar button {
            margin:0;
            border-radius: 15px;
            padding: 0px 5px 0px 5px;
        }

        /* -----------------------------------------------------
        * Modules
        * ----------------------------------------------------- */

        .modules-left > widget:first-child > #workspaces {
            margin-left: 0;
        }

        .modules-right > widget:last-child > #workspaces {
            margin-right: 0;
        }

        /* -----------------------------------------------------
        * Idle Inhibator
        * ----------------------------------------------------- */

        #idle_inhibitor {
            margin-right: 15px;
            font-size: 22px;
            font-weight: bold;
            opacity: 0.8;
            color: @iconcolor;
        }

        #idle_inhibitor.activated {
            margin-right: 15px;
            font-size: 20px;
            font-weight: bold;
            opacity: 0.8;
            color: #dc2f2f;
        }

        /* -----------------------------------------------------
        * Hardware Group
        * ----------------------------------------------------- */

        #disk,#memory,#cpu,#temperature {
            margin:0px;
            padding:0px;
            font-size:16px;
            color:@iconcolor;
        }

        #language {
            margin-right:10px;
        }

        /* -----------------------------------------------------
        * Clock
        * ----------------------------------------------------- */

        #clock {
            background-color: @backgrounddark;
            font-size: 16px;
            color: @textcolor1;
            border-radius: 15px;
            padding: 1px 10px 0px 10px;
            margin: 3px 15px 3px 0px;
            opacity:0.8;
            border:3px solid @bordercolor;   
        }

        /* -----------------------------------------------------
        * Pulseaudio
        * ----------------------------------------------------- */

        #pulseaudio {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 5px 15px 5px 0px;
            opacity:0.8;
        }

        #pulseaudio.muted {
            background-color: @backgrounddark;
            color: @textcolor1;
        }


        /* -----------------------------------------------------
        * Network
        * ----------------------------------------------------- */

        #network {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 5px 15px 5px 0px;
            opacity:0.8;
        }

        #network.ethernet {
            background-color: @backgroundlight;
            color: @textcolor2;
        }

        #network.wifi {
            background-color: @backgroundlight;
            color: @textcolor2;
        }

        /* -----------------------------------------------------
        * Bluetooth
        * ----------------------------------------------------- */

        #bluetooth, #bluetooth.on, #bluetooth.connected {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 5px 15px 5px 0px;
            opacity:0.8;
        }

        #bluetooth.off {
            background-color: transparent;
            padding: 0px;
            margin: 0px;
        }

        /* -----------------------------------------------------
        * Battery
        * ----------------------------------------------------- */

        #battery {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 15px 0px 10px;
            margin: 5px 15px 5px 0px;
            opacity:0.8;
        }

        #battery.charging, #battery.plugged {
            color: @textcolor2;
            background-color: @backgroundlight;
        }

        @keyframes blink {
            to {
                background-color: @backgroundlight;
                color: @textcolor2;
            }
        }

        #battery.critical:not(.charging) {
            background-color: #f53c3c;
            color: @textcolor3;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        /* -----------------------------------------------------
        * Tray
        * ----------------------------------------------------- */

        #tray {
            padding: 0px 15px 0px 0px;
        }

        #tray > .passive {
            -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
            -gtk-icon-effect: highlight;
        }
    '';
  };

  home.packages = with pkgs; [
    rofi
  ];
}
