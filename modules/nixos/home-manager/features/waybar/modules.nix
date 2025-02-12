{pkgs, ...}: let
  brightness-sh = pkgs.writeShellScript "waybar-brightness" (builtins.readFile ./scripts/brightness.sh);
  change-blur-sh = pkgs.writeShellScript "waybar-change-blur" (builtins.readFile ./scripts/change_blur.sh);
  volume-sh = pkgs.writeShellScript "waybar-volume" (builtins.readFile ./scripts/volume.sh);
  keyhints-sh = pkgs.writeShellScript "waybar-keyhints" (builtins.readFile ./scripts/key_hints.sh);
  wlogout-sh = pkgs.writeShellScript "waybar-wlogout" (builtins.readFile ./scripts/wlogout.sh);
  weather-py = pkgs.writers.writePython3 "waybar-weather" {libraries = [pkgs.python3Packages.pyquery];} ./scripts/weather.py;
in {
  xdg.configFile."waybar/modules".text =
    /*
    json
    */
    ''
      {
          "hyprland/workspaces": {
              "disable-scroll": true,
              "all-outputs": true,
              "format": "{icon}",
          },
          // GROUP
          "group/motherboard": {
              "orientation": "horizontal",
              "modules": [
                  "cpu",
                  "memory",
                  "temperature",
                  "disk",
              ]
          },
          "group/laptop": {
              "orientation": "horizontal",
              "modules": [
                  "backlight",
                  "battery",
              ]
          },
          "group/audio": {
              "orientation": "horizontal",
              "modules": [
                  "pulseaudio",
                  "pulseaudio#microphone",
              ]
          },
          "backlight": {
              "interval": 2,
              "align": 0,
              "rotate": 0,
              //"format": "{icon} {percent}%",
              "format-icons": [
                  "",
                  "",
                  "",
                  "󰃝",
                  "󰃞",
                  "󰃟",
                  "󰃠"
              ],
              "format": "{icon}",
              //"format-icons": ["","","","","","","","","","","","","","",""],
              "tooltip-format": "backlight {percent}%",
              "icon-size": 10,
              "on-click": "",
              "on-click-middle": "",
              "on-click-right": "",
              "on-update": "",
              "on-scroll-up": "${brightness-sh} --inc",
              "on-scroll-down": "${brightness-sh} --dec",
              "smooth-scrolling-threshold": 1,
          },
          "battery": {
              //"interval": 5,
              "align": 0,
              "rotate": 0,
              //"bat": "BAT1",
              //"adapter": "ACAD",
              "full-at": 100,
              "design-capacity": false,
              "states": {
                  "good": 95,
                  "warning": 30,
                  "critical": 15
              },
              "format": "{icon} {capacity}%",
              "format-charging": " {capacity}%",
              "format-plugged": "󱘖 {capacity}%",
              "format-alt-click": "click",
              "format-full": "{icon} Full",
              "format-alt": "{icon} {time}",
              "format-icons": [
                  "󰂎",
                  "󰁺",
                  "󰁻",
                  "󰁼",
                  "󰁽",
                  "󰁾",
                  "󰁿",
                  "󰂀",
                  "󰂁",
                  "󰂂",
                  "󰁹"
              ],
              "format-time": "{H}h {M}min",
              "tooltip": true,
              "tooltip-format": "{timeTo} {power}w",
              "on-click-middle": "${change-blur-sh}",
              "on-click-right": "${wlogout-sh}",
          },
          "clock": {
            "format": "{:%R}",
            // "timezone": "America/New_York",
            "tooltip-format": "<big>{:%Y %B}</big>\n<tt><big>{calendar}</big></tt>",
            "format-alt": "{:%Y-%m-%d}"
          },
          "cpu": {
              "format": "{usage}% 󰍛",
              "interval": 1,
              "format-alt-click": "click",
              "format-alt": "{icon0}{icon1}{icon2}{icon3} {usage:>2}% 󰍛",
              "format-icons": [
                  "▁",
                  "▂",
                  "▃",
                  "▄",
                  "▅",
                  "▆",
                  "▇",
                  "█"
              ],
              "on-click-right": "kitty --title btop sh -c 'btop'"
          },
          "disk": {
              "interval": 30,
              //"format": "󰋊",
              "path": "/",
              //"format-alt-click": "click",
              "format": "{percentage_used}% 󰋊",
              //"tooltip": true,
              "tooltip-format": "{used} used out of {total} on {path} ({percentage_used}%)",
              "on-click-right": "kitty --title btop sh -c 'btop'"
          },
          "hyprland/language": {
              "format": "{}",
              "format-en": "US",
              "format-cn": "Chinese",
              "keyboard-name": "at-translated-set-2-keyboard",
              "on-click": "hyprctl switchxkblayout $SET_KB next"
          },
          "hyprland/submap": {
              "format": "<span style=\"italic\">  {}</span>", // Icon: expand-arrows-alt
              "tooltip": false,
          },
          "hyprland/window": {
              "format": "{}",
              "max-length": 40,
              "separate-outputs": true,
              "offscreen-css": true,
              "offscreen-css-text": "(inactive)",
              "rewrite": {
                  "(.*) — Mozilla Firefox": " $1",
                  "(.*) - fish": "> [$1]",
                  "(.*) - zsh": "> [$1]",
                  "(.*) - kitty": "> [$1]",
              },
          },
          "idle_inhibitor": {
            "format": "{icon}",
            "format-icons": {
              "activated": "",
              "deactivated": ""
            }
          },
          "keyboard-state": {
              //"numlock": true,
              "capslock": true,
              "format": {
                  "numlock": "N {icon}",
                  "capslock": "󰪛 {icon}",
              },
              "format-icons": {
                  "locked": "",
                  "unlocked": ""
              },
          },
          "memory": {
              "interval": 10,
              "format": "{used:0.1f}G 󰾆",
              "format-alt": "{percentage}% 󰾆",
              "format-alt-click": "click",
              "tooltip": true,
              "tooltip-format": "{used:0.1f}GB/{total:0.1f}G",
              "on-click-right": "kitty --title btop sh -c 'btop'"
          },
          "mpris": {
              "interval": 10,
              "format": "{player_icon} ",
              "format-paused": "{status_icon} <i>{dynamic}</i>",
              "on-click-middle": "playerctl play-pause",
              "on-click": "playerctl previous",
              "on-click-right": "playerctl next",
              "scroll-step": 5.0,
              "on-scroll-up": "${volume-sh} --inc",
              "on-scroll-down": "${volume-sh} --dec",
              "smooth-scrolling-threshold": 1,
              "player-icons": {
                  "chromium": "",
                  "default": "",
                  "firefox": "",
                  "kdeconnect": "",
                  "mopidy": "",
                  "mpv": "󰐹",
                  "spotify": "",
                  "vlc": "󰕼",
              },
              "status-icons": {
                  "paused": "󰐎",
                  "playing": "",
                  "stopped": "",
              },
              // "ignored-players": ["firefox"]
              "max-length": 30,
          },
          "network": {
              "format": "{ifname}",
              "format-wifi": "{icon}",
              "format-ethernet": "󰌘",
              "format-disconnected": "󰌙",
              "tooltip-format": "{ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}",
              "format-linked": "󰈁 {ifname} (No IP)",
              "tooltip-format-wifi": "{essid} {icon} {signalStrength}%",
              "tooltip-format-ethernet": "{ifname} 󰌘",
              "tooltip-format-disconnected": "󰌙 Disconnected",
              "max-length": 50,
              "format-icons": [
                  "󰤯",
                  "󰤟",
                  "󰤢",
                  "󰤥",
                  "󰤨"
              ],
              "on-click": "kitty --title nmtui sh -c 'nmtui'"
          },
          "network#speed": {
              "interval": 1,
              "format": "{ifname}",
              "format-wifi": "{icon}  {bandwidthUpBytes}  {bandwidthDownBytes}",
              "format-ethernet": "󰌘   {bandwidthUpBytes}  {bandwidthDownBytes}",
              "format-disconnected": "󰌙",
              "tooltip-format": "{ipaddr}",
              "format-linked": "󰈁 {ifname} (No IP)",
              "tooltip-format-wifi": "{essid} {icon} {signalStrength}%",
              "tooltip-format-ethernet": "{ifname} 󰌘",
              "tooltip-format-disconnected": "󰌙 Disconnected",
              "max-length": 50,
              "format-icons": [
                  "󰤯",
                  "󰤟",
                  "󰤢",
                  "󰤥",
                  "󰤨"
              ],
              "on-click": "kitty nmtui"
          },
          "pulseaudio": {
              "format": "{icon} {volume}%",
              "format-bluetooth": "{icon} 󰂰 {volume}%",
              "format-muted": "󰖁 MUTE",
              "format-icons": {
                  "headphone": "",
                  "hands-free": "",
                  "headset": "",
                  "phone": "",
                  "portable": "",
                  "car": "",
                  "default": [
                      "",
                      "",
                      "󰕾",
                      ""
                  ],
                  "ignored-sinks": [
                      "Easy Effects Sink"
                  ],
              },
              "scroll-step": 5.0,
              "on-click": "${volume-sh} --toggle",
              "on-click-right": "pavucontrol -t 3",
              "on-scroll-up": "${volume-sh} --inc",
              "on-scroll-down": "${volume-sh} --dec",
              "tooltip-format": "{icon} {desc}",
              "smooth-scrolling-threshold": 1,
          },
          "pulseaudio#microphone": {
              "format": "{format_source}",
              "format-source": " {volume}%",
              "format-source-muted": " MUTE",
              "on-click": "${volume-sh} --toggle-mic",
              "on-click-right": "pavucontrol -t 4",
              "on-scroll-up": "${volume-sh} --mic-inc",
              "on-scroll-down": "${volume-sh} --mic-dec",
              "tooltip-format": "{source_desc}",
              "scroll-step": 5,
          },
          "temperature": {
              "interval": 10,
              "tooltip": true,
              "hwmon-path": [
                  "/sys/class/hwmon/hwmon1/temp1_input",
                  "/sys/class/thermal/thermal_zone0/temp"
              ],
              //"thermal-zone": 0,
              "critical-threshold": 82,
              "format-critical": "{temperatureC}°C {icon}",
              "format": "{temperatureC}°C {icon}",
              "format-icons": [
                  "󰈸"
              ],
              "on-click-right": "kitty --title nvtop sh -c 'nvtop'"
          },
          "tray": {
              "spacing": 10,
          },
          "custom/keybinds": {
              "format": "󰺁 HINT!",
              "exec": "echo ; echo  Key Hints SUPER H",
              "on-click": "${keyhints-sh}",
              "interval": 86400, // once every day
              "tooltip": true,
          },
          "custom/lock": {
              "format": "󰌾{}",
              "exec": "echo ; echo 󰷛  screen lock",
              "interval": 86400, // once every day
              "tooltip": true,
              "on-click": "hyprlock",
          },
          "custom/menu": {
              "format": "  ",
              "tooltip": true,
              "on-click": "rofi-toggle",
          },
          "custom/power": {
              "format": "  ",
              "on-click": "~/.config/rofi/scripts/powermenu_t5",
              "tooltip": false,
          },
          "custom/swaync": {
              "tooltip": true,
              "format": "{icon} {}",
              "format-icons": {
                  "notification": "<span foreground='red'><sup></sup></span>",
                  "none": "",
                  "dnd-notification": "<span foreground='red'><sup></sup></span>",
                  "dnd-none": "",
                  "inhibited-notification": "<span foreground='red'><sup></sup></span>",
                  "inhibited-none": "",
                  "dnd-inhibited-notification": "<span foreground='red'><sup></sup></span>",
                  "dnd-inhibited-none": ""
              },
              "return-type": "json",
              "exec-if": "which swaync-client",
              "exec": "swaync-client -swb",
              "on-click": "sleep 0.1 && swaync-client -t -sw",
              "on-click-right": "swaync-client -d -sw",
              "escape": true,
          },
          "custom/weather": {
              "format": "{}",
              "format-alt": "{alt}: {}",
              "format-alt-click": "click",
              "interval": 3600,
              "return-type": "json",
              "exec": "${weather-py}",
              "exec-if": "ping wttr.in -c1",
              "tooltip": true,
          },
          // Separators
          "custom/separator#dot": {
              "format": "",
              "interval": "once",
              "tooltip": false
          },
          "custom/separator#dot-line": {
              "format": "",
              "interval": "once",
              "tooltip": false
          },
          "custom/separator#line": {
              "format": "|",
              "interval": "once",
              "tooltip": false
          },
          "custom/separator#blank": {
              "format": "",
              "interval": "once",
              "tooltip": false
          },
          "custom/separator#blank_2": {
              "format": "  ",
              "interval": "once",
              "tooltip": false
          },
          "custom/separator#blank_3": {
              "format": "   ",
              "interval": "once",
              "tooltip": false
          },
      }
    '';
}
