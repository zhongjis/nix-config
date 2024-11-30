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
              "custom/separator#blank",
              "group/laptop",
              "custom/separator#line",
              "custom/weather",
          ],
          "modules-center": [
              "custom/swaync",
              "custom/separator#dot-line",
              "clock",
              "custom/separator#dot-line",
              "idle_inhibitor",
              "custom/hint",
          ],
          "modules-right": [
              "group/motherboard",
              "group/connections",
              "bluetooth",
              "custom/separator#line",
              "tray",
              "mpris",
              "network",
              "group/audio",
              "custom/separator#line",
              "custom/keyboard",
              "custom/lock",
              "custom/power",
          ],
      }
    '';
}
