{...}: {
  programs.waybar.style =
    /*
    css
    */
    ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        min-height: 0;
        /* set font-size to 100% if font scaling is set to 1.00 using nwg-look */
        font-size: 97%;
        font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
        padding: 1px;
      }

      /* catppuccin-mocha start */

      @define-color base   #1e1e2e;
      @define-color mantle #181825;
      @define-color crust  #11111b;

      @define-color text     #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;

      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;

      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;

      @define-color blue      #89b4fa;
      @define-color lavender  #b4befe;
      @define-color sapphire  #74c7ec;
      @define-color sky       #89dceb;
      @define-color teal      #94e2d5;
      @define-color green     #a6e3a1;
      @define-color yellow    #f9e2af;
      @define-color peach     #fab387;
      @define-color maroon    #eba0ac;
      @define-color red       #f38ba8;
      @define-color mauve     #cba6f7;
      @define-color pink      #f5c2e7;
      @define-color flamingo  #f2cdcd;
      @define-color rosewater #f5e0dc;

      /* catppuccin-mocha end */

      window#waybar {
        transition-property: background-color;
        transition-duration: 0.5s;
        background: transparent;
        /*border: 2px solid @overlay0;*/
        /*background: @theme_base_color;*/
        border-radius: 10px;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #waybar.empty #window {
        background: none;
      }

      /* This section can be use if you want to separate waybar modules */
      .modules-left,
      .modules-center,
      .modules-right {
        background: #000000;
        border: 0px solid @overlay0;
        padding-top: 0px;
        padding-bottom: 0px;
        padding-right: 4px;
        padding-left: 4px;
        border-radius: 12px;
      }

      .modules-left,
      .modules-right {
        border: 0px solid @blue;
        padding-top: 1px;
        padding-bottom: 1px;
        padding-right: 4px;
        padding-left: 4px;
      }

      #backlight,
      #backlight-slider,
      #battery,
      #bluetooth,
      #clock,
      #cpu,
      #disk,
      #idle_inhibitor,
      #keyboard-state,
      #memory,
      #mode,
      #mpris,
      #network,
      #pulseaudio,
      #pulseaudio-slider,
      #taskbar button,
      #taskbar,
      #temperature,
      #tray,
      #window,
      #wireplumber,
      #workspaces,
      #custom-backlight,
      #custom-cycle_wall,
      #custom-keybinds,
      #custom-keyboard,
      #custom-light_dark,
      #custom-lock,
      #custom-menu,
      #custom-power_vertical,
      #custom-power,
      #custom-swaync,
      #custom-updater,
      #custom-weather,
      #custom-weather.clearNight,
      #custom-weather.cloudyFoggyDay,
      #custom-weather.cloudyFoggyNight,
      #custom-weather.default,
      #custom-weather.rainyDay,
      #custom-weather.rainyNight,
      #custom-weather.severe,
      #custom-weather.showyIcyDay,
      #custom-weather.snowyIcyNight,
      #custom-weather.sunnyDay {
        padding-top: 3px;
        padding-bottom: 3px;
        padding-right: 6px;
        padding-left: 6px;
      }

      #idle_inhibitor {
        color: @blue;
      }

      #bluetooth,
      #backlight {
        color: @blue;
      }

      #battery {
        color: @green;
      }

      @keyframes blink {
        to {
          color: @surface0;
        }
      }

      #battery.critical:not(.charging) {
        background-color: @red;
        color: @theme_text_color;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
        box-shadow: inset 0 -3px transparent;
      }

      #clock {
        color: @text;
      }

      #cpu {
        color: @green;
      }

      #custom-keyboard,
      #memory {
        color: @sky;
      }

      #disk {
        color: @sapphire;
      }

      #temperature {
        color: @teal;
      }

      #temperature.critical {
        background-color: @red;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      #keyboard-state {
        color: @flamingo;
      }

      #workspaces button {
        box-shadow: none;
        text-shadow: none;
        padding: 0px;
        border-radius: 9px;
        padding-left: 4px;
        padding-right: 4px;
        animation: gradient_f 20s ease-in infinite;
        transition: all 0.5s cubic-bezier(0.55, -0.68, 0.48, 1.682);
      }

      #workspaces button:hover {
        border-radius: 10px;
        color: @overlay0;
        background-color: @surface0;
        padding-left: 2px;
        padding-right: 2px;
        animation: gradient_f 20s ease-in infinite;
        transition: all 0.3s cubic-bezier(0.55, -0.68, 0.48, 1.682);
      }

      #workspaces button.persistent {
        color: @surface1;
        border-radius: 10px;
      }

      #workspaces button.active {
        color: @teal;
        border-radius: 10px;
        padding-left: 8px;
        padding-right: 8px;
        animation: gradient_f 20s ease-in infinite;
        transition: all 0.3s cubic-bezier(0.55, -0.68, 0.48, 1.682);
      }

      #workspaces button.urgent {
        color: @red;
        border-radius: 0px;
      }

      #taskbar button.active {
        padding-left: 8px;
        padding-right: 8px;
        animation: gradient_f 20s ease-in infinite;
        transition: all 0.3s cubic-bezier(0.55, -0.68, 0.48, 1.682);
      }

      #taskbar button:hover {
        padding-left: 2px;
        padding-right: 2px;
        animation: gradient_f 20s ease-in infinite;
        transition: all 0.3s cubic-bezier(0.55, -0.68, 0.48, 1.682);
      }

      #custom-cava_mviz {
        color: @pink;
      }

      #custom-menu {
        color: @teal;
      }

      #custom-power {
        color: @red;
      }

      #custom-updater {
        color: @red;
      }

      #custom-light_dark {
        color: @blue;
      }

      #custom-weather {
        color: @lavender;
      }

      #custom-lock {
        color: @maroon;
      }

      #pulseaudio {
        color: @green;
      }

      #pulseaudio.bluetooth {
        color: @pink;
      }

      #pulseaudio.muted {
        color: @red;
      }

      #pulseaudio.source-muted {
        color: @red;
      }

      #window {
        color: @mauve;
      }

      #custom-waybar-mpris {
        color: @lavender;
      }

      #network {
        color: @teal;
      }
      #network.disconnected,
      #network.disabled {
        background-color: @surface0;
        color: @red;
      }
      #pulseaudio-slider slider {
        min-width: 0px;
        min-height: 0px;
        opacity: 0;
        background-image: none;
        border: none;
        box-shadow: none;
      }

      #pulseaudio-slider trough {
        min-width: 80px;
        min-height: 5px;
        border-radius: 5px;
      }

      #pulseaudio-slider highlight {
        min-height: 10px;
        border-radius: 5px;
      }

      #backlight-slider slider {
        min-width: 0px;
        min-height: 0px;
        opacity: 0;
        background-image: none;
        border: none;
        box-shadow: none;
      }

      #backlight-slider trough {
        min-width: 80px;
        min-height: 10px;
        border-radius: 5px;
      }

      #backlight-slider highlight {
        min-width: 10px;
        border-radius: 5px;
      }
    '';
}
