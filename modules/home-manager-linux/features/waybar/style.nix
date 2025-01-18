{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    nerd-fonts.mononoki
    font-awesome_6
    font-awesome_5
    font-awesome_4
  ];

  programs.waybar.style = with config.lib.stylix.colors;
  /*
  css
  */
    ''
      /*
      *
      * Catppuccin Mocha palette
      * Maintainer: rubyowo
      *
      */

      @define-color background #${base00};
      @define-color color1 #${base01};
      @define-color color2 #${base02};
      @define-color color3 #${base03};
      @define-color color4 #${base04};
      @define-color color5 #${base05};
      @define-color color6 #${base06};
      @define-color color7 #${base07};
      @define-color color8 #${base08};
      @define-color color9 #${base09};
      @define-color color10 #${base0A};
      @define-color color11 #${base0B};
      @define-color color12 #${base0C};
      @define-color color13 #${base0D};
      @define-color color14 #${base0E};
      @define-color color15 #${base0F};

      * {
        font-family: Mononoki, "Font Awesome 6 Free", "Font Awesome 6 Brands";
        font-size: 14px;
        font-weight: bold;
      }

      window#waybar {
        background-color: transparent;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      button {
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 100%;
      }

      button:hover {
        background: inherit;
      }

      #pulseaudio:hover {
      }

      #window {
        font-size: 9px;
        color: @background;
      }

      #workspaces button {
        background-color: transparent;
        padding: 0px 4px;
        color: @color5;
        font-weight: 100;
      }

      #workspaces button.active {
        color: @color6;
      }

      #workspaces button.urgent {
        color: @color1;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #custom-mem,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #power-profiles-daemon,
      #mpd {
        padding: 0 10px;
        color: @foreground;
      }

      #window,
      #workspaces {
        margin: 0 5px 0 0px;
      }

      /* If workspaces is the leftmost module, omit left margin */
      .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
      .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
      }

      #custom-os_button {
        color: @background;
        font-size: 1.2rem;
        padding: 0 12px 0 8px;
        margin-left: 4px;
        margin-top: 4px;
        margin-bottom: 4px;
        border-radius: 100px;
        background-color: @color4;
      }

      #custom-power {
        color: @background;
        padding: 0 10px 0 10px;
        margin-left: 2px;
        margin-right: 4px;
        margin-top: 4px;
        margin-bottom: 4px;
        border-radius: 100px;
        background-color: @color5;
      }

      #custom-power:hover {
        transition: ease 0.2s all;
        color: @color5;
        background-color: @background;
      }

      #clock {
        margin-right: 4px;
        margin-top: 3px;
        margin-bottom: 3px;
        border-radius: 0 100px 100px 0;
      }

      #battery {
        margin-bottom: 3px;
        margin-top: 3px;
      }

      #battery.charging,
      #battery.plugged {
        color: #26a65b;
      }

      @keyframes blink {
        to {
          color: #ffffff;
        }
      }

      /* Using steps() instead of linear as a timing function to limit cpu usage */
      #battery.critical:not(.charging) {
        color: #f53c3c;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      label:focus {
        background-color: #000000;
      }

      #custom-mem {
        background-color: transparent;
        margin-right: 6px;
        margin-left: 6px;
      }

      #disk {
        background-color: transparent;
      }

      #backlight {
        background-color: transparent;
      }

      #network {
        background-color: transparent;
      }

      #network.disconnected {
        color: #f53c3c;
      }

      #pulseaudio {
        margin-left: 4px;
        background-color: transparent;
      }

      #pulseaudio.muted {
        background-color: transparent;
      }

      #temperature {
        background-color: transparent;
      }

      #temperature.critical {
        color: #eb4d4b;
      }

      #idle_inhibitor {
        background-color: #2d3436;
      }

      #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
      }

      #scratchpad {
        background: rgba(0, 0, 0, 0.2);
      }

      #scratchpad.empty {
        background-color: transparent;
      }

      #privacy {
        padding: 0;
      }

      #privacy-item {
        padding: 0 5px;
        color: white;
      }

      #privacy-item.screenshare {
        background-color: #cf5700;
      }

      #privacy-item.audio-in {
        background-color: #1ca000;
      }

      #privacy-item.audio-out {
        background-color: #0069d4;
      }

      .modules-left {
        margin: 10px 0 0 10px;
        background-color: @background;
        border-radius: 40px;
      }

      .modules-center {
        margin: 10px 0 0 0;
      }

      .modules-right {
        margin: 10px 10px 0 0;
        background-color: @background;
        border-radius: 40px;
      }
    '';
}
