{ 
    pkgs, 
    ... 
}:let 
    mainBarConfig = {
        layer = "top";
        position = "top";
        height = 35;
        spacing = 4;
        modules-left = [ 
            "wlr/taskbar" 
            "hyprland/window"
        ];
        modules-center = [
            "hyprland/workspaces"
        ];
        modules-right = [
            "pulseaudio"
            "bluetooth"
            "cpu"
            "memory"
            "temperature"
            "network"
            "battery"
            "clock"
        ];

        "hyprland/workspaces" = {
            format = "[{id}]";
        };

        "hyprland/window" = {
            format = "[{title}]";
        };

        "clock"= {
            tooltip-format = "<big>[{:%Y %B}]</big>\n<tt><small>{calendar}</small></tt>";
            format = "[{:%H:%M}]";
            format-alt = "[{:%Y-%m-%d}]";
        };

        "cpu"= {
            format = "[CPU:{usage}%]";
            tooltip = false;
        };

        "memory"= {
            format = "[MEM:{percentage}%]";
        };

        "temperature"= {
            # "thermal-zone"= 2;
            # "hwmon-path"= "/sys/class/hwmon/hwmon2/temp1_input";
            critical-threshold = 80;
            # "format-critical"= "{temperatureC}°C {icon}";
            format-critical = "[!!{temperatureC}°C!!]";
            format = "[{temperatureC}°C]";
        };

        "backlight"= {
            # "device"= "acpi_video1";
            format = "{percent}% {icon}";
            format-icons = ["" "" "" "" "" "" "" "" ""];
        };

        "battery"= {
            format = "[BAT:{capacity}%]";
            format-charging = "[BAT:{capacity}%+]";
        };

        "network" = {
            format = "{ifname}";
            format-wifi = "[WIFI:{signalStrength}%]";
            format-ethernet = "[ETH:{ifname}]";
            format-disconnected = "[Disconnected]";
            tooltip-format = " {ifname} via {gwaddri}";
            tooltip-format-wifi = "  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
            tooltip-format-ethernet = " {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}";
            max-length = 50;
            # on-click = "~/dotfiles/.settings/networkmanager.sh";
        };

        "pulseaudio" = {
            format = "[VOL:{volume}%]";
            format-muted = "[VOL: -]";
            on-click = "pavucontrol";
        };

        "bluetooth" = {
            format = " {status}";
            format-disabled = "";
            format-off = "";
            interval = 30;
            on-click = "blueman-manager";
            format-no-controller = "";
        };
    };

    css = ''
@define-color accent #383838;
@define-color text #f8f8f8;
@define-color invText #f8f8f8;
/* text when background is accent */
@define-color bg #181818;


/* @import "./wal.css";
@define-color accent @color5;
@define-color bg @background;
@define-color text @foreground; */

/*
*
* Base16 Default Dark
* Author: Chris Kempson (http://chriskempson.com)
*
*/

@define-color base00 #181818;
@define-color base01 #282828;
@define-color base02 #383838;
@define-color base03 #585858;
@define-color base04 #b8b8b8;
@define-color base05 #d8d8d8;
@define-color base06 #e8e8e8;
@define-color base07 #f8f8f8;
@define-color base08 #ab4642;
@define-color base09 #dc9656;
@define-color base0A #f7ca88;
@define-color base0B #a1b56c;
@define-color base0C #86c1b9;
@define-color base0D #7cafc2;
@define-color base0E #ba8baf;
@define-color base0F #a16946;

@define-color accent @base01;
@define-color text @base07;
@define-color invText @base07;
@define-color bg @base00;

* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 16;
  border-radius: 2px;
  /* :[ */
  min-height: 0px;
}

.modules-left {
  background-color: @bg;
  padding: 0px 0px 0px 0px;
}

.modules-center {
  background-color: @bg;
  padding: 0px 0px 0px 0px;
}

.modules-right {
  background-color: @bg;
  padding: 0px 0px 0px 0px;
}

window#waybar {
  background-color: @bg;
  color: @text;
  opacity: 1;
}

#workspaces {
  background-color: transparent;
}

#workspaces button {
  padding: 0 5px;
	color: @text;
}

#workspaces button.active {
  background-color: @accent;
  color: @invText;
  /* color: @background; */
}

#taskbar,
#window,
#workspaces,
#pulseaudio,
#bluetooth,
#cpu,
#memory,
#temperature,
#network,
#battery,
#clock
{
  background-color: transparent;
  color: @text;
  margin: 0px;
}

#window {
  color: @invText;
  /* background-color: @accent; */
  padding-left: 4px;
}
    '';
in {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    });
    settings.mainBar = mainBarConfig;
    style = css;
  };

  home.packages = with pkgs; [
    rofi
  ];
}
