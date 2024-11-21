{pkgs, ...}: let
  cava-sh = pkgs.writeShellScript "hypr-cava.sh" ./scripts/cava_viz.sh;
  brightness-sh = pkgs.writeShellScript "hypr-brightness.sh" ./scripts/brightness.sh;
  change-blur-sh = pkgs.writeShellScript "hypr-change-blur.sh" ./scripts/change_blur.sh;
  volume-sh = pkgs.writeShellScript "hypr-volume.sh" ./scripts/volume.sh;
  keyhints-sh = pkgs.writeShellScript "hypr-keyhints.sh" ./scripts/key_hints.sh;
  wlogout-sh = pkgs.writeShellScript "hypr-keyhints.sh" ./scripts/wlogout.sh;
  weather-py = pkgs.writers.writePython3 "hypr-weather.py" {libraries = [pkgs.python3Packages.pyquery];} ./scripts/weather.py;
in {
  fileText =
    /*
    json
    */
    ''
      {
          "hyprland/workspaces": {
              "active-only": false,
              "all-outputs": true,
              "format": "{icon}",
              "show-special": false,
              "on-click": "activate",
              "on-scroll-up": "hyprctl dispatch workspace e+1",
              "on-scroll-down": "hyprctl dispatch workspace e-1",
              "persistent-workspaces": {
                  "1": [],
                  "2": [],
                  "3": [],
                  "4": [],
                  "5": [],
              },
              "format-icons": {
                  "active": "",
                  "default": "",
              },
          },
          // ROMAN Numerals style
          "hyprland/workspaces#roman": {
              "active-only": false,
              "all-outputs": true,
              "format": "{icon}",
              "show-special": false,
              "on-click": "activate",
              "on-scroll-up": "hyprctl dispatch workspace e+1",
              "on-scroll-down": "hyprctl dispatch workspace e-1",
              "persistent-workspaces": {
                  "1": [],
                  "2": [],
                  "3": [],
                  "4": [],
                  "5": [],
              },
              "format-icons": {
                  "1": "I",
                  "2": "II",
                  "3": "III",
                  "4": "IV",
                  "5": "V",
                  "6": "VI",
                  "7": "VII",
                  "8": "VIII",
                  "9": "IX",
                  "10": "X",
              },
          },
          // PACMAN Style
          "hyprland/workspaces#pacman": {
              "active-only": false,
              "all-outputs": true,
              "format": "{icon}",
              "on-click": "activate",
              "on-scroll-up": "hyprctl dispatch workspace e+1",
              "on-scroll-down": "hyprctl dispatch workspace e-1",
              "show-special": false,
              "persistent-workspaces": {
                  "1": [],
                  "2": [],
                  "3": [],
                  "4": [],
                  "5": [],
              },
              "format": "{icon}",
              "format-icons": {
                  "active": " 󰮯 ",
                  "default": "󰊠",
                  "persistent": "󰊠",
              },
          },
          "hyprland/workspaces#kanji": {
              "disable-scroll": true,
              "all-outputs": true,
              "format": "{icon}",
              "persistent-workspaces": {
                  "1": [],
                  "2": [],
                  "3": [],
                  "4": [],
                  "5": [],
              },
              "format-icons": {
                  "1": "一",
                  "2": "二",
                  "3": "三",
                  "4": "四",
                  "5": "五",
                  "6": "六",
                  "7": "七",
                  "8": "八",
                  "9": "九",
                  "10": "十",
              }
          },
          //  NUMBERS and ICONS style
          "hyprland/workspaces#4": {
              "format": "{name}",
              //"format": " {name} {icon} ",
              "format": " {icon} ",
              "show-special": false,
              "on-click": "activate",
              "on-scroll-up": "hyprctl dispatch workspace e+1",
              "on-scroll-down": "hyprctl dispatch workspace e-1",
              "all-outputs": true,
              "sort-by-number": true,
              "format-icons": {
                  "1": " ",
                  "2": " ",
                  "3": " ",
                  "4": " ",
                  "5": " ",
                  "6": " ",
                  "7": "",
                  "8": " ",
                  "9": "",
                  "10": "10",
                  "focused": "",
                  "default": "",
              },
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
                  " ",
                  " ",
                  " ",
                  "󰃝 ",
                  "󰃞 ",
                  "󰃟 ",
                  "󰃠 "
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
              "format-charging": "{capacity}%",
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
          "bluetooth": {
              "format": "",
              "format-disabled": "󰂳",
              "format-connected": "󰂱 {num_connections}",
              "tooltip-format": " {device_alias}",
              "tooltip-format-connected": "{device_enumerate}",
              "tooltip-format-enumerate-connected": " {device_alias} 󰂄{device_battery_percentage}%",
              "tooltip": true,
              "on-click": "blueman-manager",
          },
          "clock": {
              "interval": 1,
              // "format": " {:%I:%M %p}", // AM PM format
              "format": " {:%H:%M:%S}",
              "format-alt": " {:%H:%M   %Y, %d %B, %A}",
              "tooltip-format": "<tt><small>{calendar}</small></tt>",
              "calendar": {
                  "mode": "year",
                  "mode-mon-col": 3,
                  "weeks-pos": "right",
                  "on-scroll": 1,
                  "format": {
                      "months": "<span color='#ffead3'><b>{}</b></span>",
                      "days": "<span color='#ecc6d9'><b>{}</b></span>",
                      "weeks": "<span color='#99ffdd'><b>W{}</b></span>",
                      "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
                      "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
                  }
              }
          },
          "actions": {
              "on-click-right": "mode",
              "on-click-forward": "tz_up",
              "on-click-backward": "tz_down",
              "on-scroll-up": "shift_up",
              "on-scroll-down": "shift_down"
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
              "on-click-right": "gnome-system-monitor",
          },
          "disk": {
              "interval": 30,
              //"format": "󰋊",
              "path": "/",
              //"format-alt-click": "click",
              "format": "{percentage_used}% 󰋊",
              //"tooltip": true,
              "tooltip-format": "{used} used out of {total} on {path} ({percentage_used}%)",
          },
          "hyprland/language": {
              "format": "Lang: {}",
              "format-en": "US",
              "format-tr": "Korea",
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
                  "activated": " ",
                  "deactivated": " ",
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
              ]
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
              ]
          },
          "pulseaudio": {
              "format": "{icon} {volume}%",
              "format-bluetooth": "{icon} 󰂰 {volume}%",
              "format-muted": "󰖁",
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
              "tooltip-format": "{icon} {desc} | {volume}%",
              "smooth-scrolling-threshold": 1,
          },
          "pulseaudio#microphone": {
              "format": "{format_source}",
              "format-source": " {volume}%",
              "format-source-muted": "",
              "on-click": "${volume-sh} --toggle-mic",
              "on-click-right": "pavucontrol -t 4",
              "on-scroll-up": "${volume-sh} --mic-inc",
              "on-scroll-down": "${volume-sh} --mic-dec",
              "tooltip-format": "{source_desc} | {source_volume}%",
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
              "icon-size": 15,
              "spacing": 8,
          },
          "wireplumber": {
              "format": "{icon} {volume} %",
              "format-muted": " Mute",
              "on-click": "${volume-sh} --toggle",
              "on-click-right": "pavucontrol -t 3",
              "on-scroll-up": "${volume-sh} --inc",
              "on-scroll-down": "${volume-sh} --dec",
              "format-icons": [
                  "",
                  "",
                  "󰕾",
                  ""
              ],
          },
          "wlr/taskbar": {
              "format": "{icon} {name} ",
              "icon-size": 15,
              "all-outputs": false,
              "tooltip-format": "{title}",
              "on-click": "activate",
              "on-click-middle": "close",
              "ignore-list": [
                  "wofi",
                  "rofi",
              ]
          },
          "custom/keybinds": {
              "format": "󰺁 HINT!",
              "exec": "echo ; echo  Key Hints SUPER H",
              "on-click": "${keyhints-sh}",
              "interval": 86400, // once every day
              "tooltip": true,
          },
          "custom/light_dark": {
              "format": "{}",
              "exec": "echo ; echo 󰔎 Dark-Light switcher",
              "on-click": "~/.config/hypr/scripts/DarkLight.sh",
              "on-click-right": "~/.config/hypr/scripts/WaybarStyles.sh",
              "on-click-middle": "~/.config/hypr/scripts/Wallpaper.sh",
              "interval": 86400, // once every day
              "tooltip": true
          },
          "custom/lock": {
              "format": "󰌾{}",
              "exec": "echo ; echo 󰷛  screen lock",
              "interval": 86400, // once every day
              "tooltip": true,
              "on-click": "hyprlock",
          },
          "custom/menu": {
              "format": " {}",
              "exec": "echo ; echo 󱓟 app launcher",
              "interval": 86400, // once every day
              "tooltip": true,
              "on-click": "pkill rofi || rofi -show drun -modi run,drun,filebrowser,window",
              "on-click-middle": "~/.config/hypr/scripts/WallpaperSelect.sh",
              "on-click-right": "~/.config/hypr/scripts/WaybarLayout.sh",
          },
          // This is a custom cava visualizer
          "custom/cava_mviz": {
              "exec": "${cava-sh}",
              "format": "{}"
          },
          "custom/playerctl": {
              "format": "<span>{}</span>",
              "return-type": "json",
              "max-length": 35,
              "exec": "playerctl -a metadata --format '{\"text\": \"{{artist}} ~ {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F",
              "on-click-middle": "playerctl play-pause",
              "on-click": "playerctl previous",
              "on-click-right": "playerctl next",
              "scroll-step": 5.0,
              "on-scroll-up": "${volume-sh} --inc",
              "on-scroll-down": "${volume-sh} --dec",
              "smooth-scrolling-threshold": 1,
          },
          "custom/power": {
              "format": "⏻ ",
              "exec": "echo ; echo 󰟡 power // blur",
              "on-click": "${wlogout-sh}",
              "on-click-right": "${change-blur-sh}",
              "interval": 86400, // once every day
              "tooltip": true,
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
              //"exec": "~/.config/hypr/UserScripts/Weather.py",
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
