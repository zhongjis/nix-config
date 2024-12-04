# Script for Monitor backlights (if supported) using brightnessctl

# Get brightness
get_backlight() {
  echo $(brightnessctl -m | cut -d, -f4)
}

# Change brightness
change_backlight() {
  brightnessctl set "$1" -n
}

# Execute accordingly
case "$1" in
  "--get")
    get_backlight
    ;;
  "--inc")
    change_backlight "+5%"
    ;;
  "--dec")
    change_backlight "5%-"
    ;;
  *)
    get_backlight
    ;;
esac
