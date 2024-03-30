#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
	Rofi is running, kill it
	rofi
else
	# Rofi not running, launch it
	rofi -show drun
	sleep 0.2          # Small delay to let Rofi open
	hyprctl dispatch focuswindow active
fi
