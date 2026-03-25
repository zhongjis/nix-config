{pkgs, ...}: let
  brightness-sh = pkgs.writeShellScript "waybar-brightness" (builtins.readFile ./scripts/brightness.sh);
  change-blur-sh = pkgs.writeShellScript "waybar-change-blur" (builtins.readFile ./scripts/change_blur.sh);
  volume-sh = pkgs.writeShellScript "waybar-volume" (builtins.readFile ./scripts/volume.sh);
  keyhints-sh = pkgs.writeShellScript "waybar-keyhints" (builtins.readFile ./scripts/key_hints.sh);
  wlogout-sh = pkgs.writeShellScript "waybar-wlogout" (builtins.readFile ./scripts/wlogout.sh);
  weather-py = pkgs.writers.writePython3 "waybar-weather" {libraries = [pkgs.python3Packages.pyquery];} ./scripts/weather.py;
  memory-usage-sh = pkgs.writeShellScript "memory-usage" (builtins.readFile ./scripts/memory_usage.sh);
  hyprsunset-sh = pkgs.writeShellScript "waybar-hyprsunset" (builtins.readFile ./scripts/hyprsunset.sh);
in {
  xdg.configFile."waybar/modules".text =
    /*
    json
    */
    ''
      {
          "custom/rofi": {
              "format": "<span ></span>",
              "on-click": "rofi -show drun -disable-history -show-icons",
              "on-click-right": "rofi-toggle-power-menu",
              "escape": true,
              "tooltip": false
          },
          "hyprland/workspaces": {
              "disable-scroll": true,
              "active-only": false,
              "all-outputs": true,
              "warp-on-scroll": false,
              "format": "{icon}",
              "format-icons": {
                  "1": "<span >󱄅</span>",
                  "2": "<span >󱩛</span>",
                  "3": "<span >󰧨</span>",
                  "spotify": "<span ></span>",
                  "zen": "<span ></span>",
                  "gaming": "<span ></span>",
                  "obsidian": "<span >󰠮</span>",
              }
          },
          "hyprland/window": {
              "format": "<span color='#202020' bgcolor='#d3869b' > 󰣆 </span> {class}",
              "separate-outputs": true,
              "icon": false,
          },
          "tray": {
              "icon-size": 15,
              "spacing": 8
          },
          "disk": {
              "format": "<span color='#202020' bgcolor='#ea6962' >  </span> {free}",
              "interval": 20
          },
          "cpu": {
              "format": "<span color='#202020' bgcolor='#e78a4e' >  </span> {usage}%",
              "tooltip": false,
              "interval": 1,
              "on-click-right": "${pkgs.ghostty}/bin/ghostty --title=btop -e btop"
          },
          "temperature": {
              "tooltip": false,
              "thermal-zone": 2,
              "hwmon-path": "/sys/class/hwmon/hwmon1/temp1_input",
              "critical-threshold": 70,
              "format": "<span color='#202020' bgcolor='#d8a657' >  </span> {temperatureC}°C",
              "format-critical": "<span color='#202020' bgcolor='#cc241d' >  </span> {temperatureC}°C",
              "on-click-right": "${pkgs.ghostty}/bin/ghostty --title=nvtop -e nvtop"
          },
          "backlight": {
              // "device": "acpi_video1",
              "format": "<span color='#202020' bgcolor='#458588' > 󰞏 </span> {percent}%",
              "tooltip": false,
              "on-scroll-up": "${brightness-sh} --inc",
              "on-scroll-down": "${brightness-sh} --dec",
          },
          "network": {
              "format": "{ifname}",
              "format-wifi": "<span color='#202020' bgcolor='#7c80b2' > {icon} </span> WIFI",
              "format-ethernet": "<span color='#202020' bgcolor='#7c80b2' > 󰌘 </span> ETH",
              "format-disconnected": "<span color='#202020' bgcolor='#7c80b2' > 󰌙 </span> DISCONNECTED",
              "format-linked": "<span color='#202020' bgcolor='#7c80b2' > 󰈁 </span> {ifname} (No IP)",
              "tooltip-format": "{ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}",
              "tooltip-format-wifi": "{essid} {icon} {signalStrength}%",
              "tooltip-format-ethernet": "{ifname}",
              "tooltip-format-disconnected": "Disconnected",
              "max-length": 50,
              "format-icons": [
                  "󰤯",
                  "󰤟",
                  "󰤢",
                  "󰤥",
                  "󰤨"
              ],
              "on-click": "${pkgs.ghostty}/bin/ghostty --title=nmtui -e nmtui"
          },
          "custom/memory": {
              "exec": "${memory-usage-sh}",
              "interval": 2,
              "return-type": "json",
              "format": "<span color='#202020' bgcolor='#f6c657' >  </span> {}"
          },
          "pulseaudio": {
              // "scroll-step": 1, // %, can be a float
              "format": "<span color='#202020' bgcolor='#83a598' >  </span> {volume}%",
              "format-muted": "<span color='#202020' bgcolor='#ea6962' >  </span> {volume}%",
              "format-bluetooth": "<span color='#202020' bgcolor='#83a598' > 󰂰 </span> {volume}%",
              "format-bluetooth-muted": "<span color='#202020' bgcolor='#ea6962' > 󰂲 </span> {volume}%",
              "format-source": "{volume}% ",
              "on-click": "${volume-sh} --toggle",
              "on-click-right": "pavucontrol -t 3",
              "on-scroll-up": "${volume-sh} --inc",
              "on-scroll-down": "${volume-sh} --dec",
              "tooltip-format": "{desc}",
              "max-volume": 130
          },
          "pulseaudio#microphone": {
              "format": "{format_source}",
              "format-source": "<span color='#202020' bgcolor='#83a598' >  </span> {volume}%",
              "format-source-muted": "<span color='#202020' bgcolor='#ea6962' >  </span> {volume}%",
              "on-click": "${volume-sh} --toggle-mic",
              "on-click-right": "pavucontrol -t 4",
              "on-scroll-up": "${volume-sh} --mic-inc",
              "on-scroll-down": "${volume-sh} --mic-dec",
              "tooltip-format": "{source_desc}",
              "scroll-step": 5,
          },
        "custom/hyprsunset": {
            "exec": "${hyprsunset-sh}",
            "return-type": "json",
            "interval": 5,
            "format": "{}",
            "on-click": "${hyprsunset-sh} --toggle",
            "tooltip": true
        },
          "battery#bat2": {
              "bat": "BAT2"
          },
          "battery": {
              "interval": 1,
              "states": {
                  "good": 99,
                  "warning": 30,
                  "critical": 20
              },
              "format-icons": [
                  "󰂎",
                  "󰁺",
                  "󰁻",
                  "󰁽",
                  "󰁾",
                  "󰁿",
                  "󰂀",
                  "󰂁",
                  "󰂂",
                  "󰁹"
              ],
              "format": "<span color='#202020' bgcolor='#689d6a' > {icon} </span> {capacity}%",
              "format-critical": "<span color='#202020' bgcolor='#cc241d' > {icon} </span> {capacity}%!!",
              "format-warning": "<span color='#202020' bgcolor='#e78a4e' > {icon} </span> {capacity}%",
              "format-full": "<span color='#202020' bgcolor='#689d6a' > {icon} </span> {capacity}%",
              "format-charging": "<span color='#202020' bgcolor='#689d6a' > 󰂅 </span> {capacity}%",
              "format-charging-warning": "<span color='#202020' bgcolor='#e78a4e' > 󰢝 </span> {capacity}%",
              "format-charging-critical": "<span color='#202020' bgcolor='#cc241d' > 󰢜 </span> {capacity}%",
              "format-plugged": "<span color='#202020' bgcolor='#689d6a' > 󰂅 </span> {capacity}%",
              "format-alt": "<span color='#202020' bgcolor='#689d6a' > 󱧥 </span> {time}",
              "tooltip": false
          },
          "clock": {
              // "timezone": "America/New_York",
              "format": "<span color='#202020' bgcolor='#8ec07c' >  </span> {:%a %d %b %H:%M:%S}",
              "tooltip": false,
              "interval": 1,
          }
      }
    '';
}
