{...}: {
  xdg.configFile."waybar/config".text =
    /*
    json
    */
    ''
      {
        "include": "~/.config/waybar/modules",
        "layer": "top",
        "mode":"dock",
        "height": 20,
        "spacing": 5,
        "margin-top" :5,
        "margin-left" :5,
        "margin-right" :5,

        "modules-left": [
          "custom/rofi",
          "hyprland/workspaces",
          "hyprland/window",
          "tray",
        ],

        "modules-center": [
          "clock"
        ],

        "modules-right": [
          "disk",
          "cpu",
          "temperature",
          "custom/memory",
          "network",
          "backlight",
          "pulseaudio",
          "custom/hyprsunset",
          "battery",
        ],
      }
    '';
}
