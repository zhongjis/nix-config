#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
  # Rofi is running, kill it
  pkill rofi
else
  # Rofi not running, launch it
  rofi -show power-menu -modi power-menu:rofi-power-menu
  # rofi -show drun -show-icons
  sleep 0.2 # Small delay to let Rofi open
  hyprctl dispatch focuswindow active
fi
