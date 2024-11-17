{
  fileText =
    /*
    json
    */
    ''
      {
      	"include": "~/.config/waybar/modules",
      	"layer": "top",
      	//"mode": "dock",
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
      		"custom/light_dark",
      		"custom/separator#dot-line",
      		"power-profiles-daemon",
      		"group/mobo_drawer",
      		"custom/separator#blank",
      		"group/laptop",
      		"custom/separator#line",
      		"custom/weather",
      	],
      	"modules-center": [
      		"custom/swaync",
      		"custom/cava_mviz",
      		"custom/separator#dot-line",
      		"clock",
      		"custom/separator#line",
      		"hyprland/workspaces#kanji",
      		"custom/separator#dot-line",
      		"idle_inhibitor",
      		"custom/hint",
      	],
      	"modules-right": [
      		"network#speed",
      		"group/connections",
      		"custom/separator#line",
      		"tray",
      		"mpris",
      		"group/audio",
      		"custom/separator#line",
      		"keyboard-state",
      		"custom/keyboard",
      		"custom/lock",
      		"custom/power",
      	],
      }
    '';
}
