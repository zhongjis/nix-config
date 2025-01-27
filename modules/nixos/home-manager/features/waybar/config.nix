{...}: {
  xdg.configFile."waybar/config".text =
    /*
    json
    */
    ''
      {
          "include": "~/.config/waybar/modules",
          "spacing": 4,
          "modules-left": [
              "custom/menu",
              "custom/separator#blank",
              "battery",
              "group/motherboard",
          ],
          "modules-center": [
          ],
          "modules-right": [
              "tray",
              "network",
              "group/audio",
              "backlight",
              "idle_inhibitor",
              "clock",
              "custom/power",
          ],
      }
    '';
}
