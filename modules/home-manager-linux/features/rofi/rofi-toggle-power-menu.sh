#!/usr/bin/env bash

# Detect whether we're running on Xorg or Wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  suspend="systemctl suspend && hyprlock"
else
  # not implemented
  suspend="systemctl suspend && i3lock -i ~/.config/walls/VIM.png"
fi

logout() {
  if [ "$DESKTOP_SESSION" = "i3" ]; then
    killall i3
  elif [ "$DESKTOP_SESSION" = "sway" ]; then
    killall sway
  elif uwsm check is-active hyprland.desktop; then
    uwsm stop
  else
    hyprctl dispatch exit
  fi
}

# Present the power menu dependin od display server

# if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
#     chosen=$(printf "Log Out\nSuspend\nRestart\nPower OFF" |  fuzzel --dmenu -l 4 --width 10 --anchor top-left -p "menu : ")
#   elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
#     chosen=$(printf "Log Out\nSuspend\nRestart\nPower OFF" | rofi -dmenu -i -theme-str '@import "~/.config/rofi/powermenu.rasi"')
# fi

chosen=$(printf "Log Out\nSuspend\nRestart\nPower OFF" | rofi -dmenu -i -theme-str '@import "~/.config/rofi/powermenu.rasi"')

# Perform the action based on user choice
case "$chosen" in
  "Log Out") logout ;;
  "Suspend") eval "$suspend" ;;
  "Restart") systemctl reboot ;;
  "Power OFF") systemctl poweroff ;;
  *) exit 1 ;;
esac
