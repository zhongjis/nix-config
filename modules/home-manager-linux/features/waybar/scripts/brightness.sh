# Script for Monitor backlights (if supported) using brightnessctl

# Get brightness
get_backlight() {
  brightnessctl -m | cut -d, -f4
}

# Change brightness
change_backlight() {
  brightnessctl set "$1" -n
}

# Notify brightness
notify_brightness() {
  brightness=$(get_backlight)
  notify-send -e -h int:value:"$brightness" -h "string:x-canonical-private-synchronous:brightness_notif" -u low "Brightness-Level: $brightness"
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
  get_backlight
elif [[ "$1" == "--inc" ]]; then
  change_backlight "+5%"
  notify_brightness
elif [[ "$1" == "--dec" ]]; then
  change_backlight "5%-"
  notify_brightness
else
  get_backlight
fi
