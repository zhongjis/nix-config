{...}: {
  xdg.configFile."waybar/config".text =
    /*
    json
    */
    ''
      {
          "include": "~/.config/waybar/modules",
          "layer": "top",
          "exclusive": true,
          "passthrough": false,
          "position": "top",
          "spacing": 3,
          "fixed-center": true,
          "ipc": true,
          "margin-top": 3,
          "margin-left": 8,
          "margin-right": 8,
          "modules-left": [
              "custom/menu",
              "battery",
              "group/motherboard",
          ],
          "modules-center": [
              "custom/swaync",
              "custom/separator#dot-line",
              "mpris",
              "custom/separator#dot-line",
              "idle_inhibitor",
              "custom/hint",
          ],
          "modules-right": [
              "tray",
              "network",
              "group/audio",
              "backlight",
              "clock",
              "custom/power",
          ],
      }
    '';
}
