# Scripts for volume controls for audio and mic

# Get Volume
get_output_vol() {
  volume=$(pamixer --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume%"
  fi
}

# Notify
notify_output_vol() {
  volume=$(get_output_vol)
  notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low "Speaker-Level: $volume"
}

# Increase Volume
inc_output_vol() {
  if [ "$(pamixer --get-mute)" == "true" ]; then
    toggle_output
  else
    pamixer -i 5 --allow-boost --set-limit 150 && notify_output_vol
  fi
}

# Decrease Volume
dec_output_vol() {
  if [ "$(pamixer --get-mute)" == "true" ]; then
    toggle_output
  else
    pamixer -d 5 && notify_output_vol
  fi
}

# Toggle Mute
toggle_output() {
  if [ "$(pamixer --get-mute)" == "false" ]; then
    pamixer -m && notify-send -e -h int:value:"0" -h "string:x-canonical-private-synchronous:volume_notif" -u low "Speaker-Level: MUTED"
  elif [ "$(pamixer --get-mute)" == "true" ]; then
    pamixer -u && notify_output_vol
  fi
}

# Toggle Mic
toggle_input() {
  if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
    pamixer --default-source -m && notify-send -e -h int:value:"0" -h "string:x-canonical-private-synchronous:volume_notif" -u low "Mic-Level: MUTED"
  elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    pamixer -u --default-source u && notify_input_vol
  fi
}

# Get Microphone Volume
get_input_vol() {
  volume=$(pamixer --default-source --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume%"
  fi
}

# Notify for Microphone
notify_input_vol() {
  volume=$(get_input_vol)
  notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low "Mic-Level: $volume"
}

# Increase MIC Volume
increase_input_vol() {
  if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    toggle_input
  else
    pamixer --default-source -i 5 && notify_input_vol
  fi
}

# Decrease MIC Volume
decrease_input_vol() {
  if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    toggle-mic
  else
    pamixer --default-source -d 5 && notify_input_vol
  fi
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
  get_output_vol
elif [[ "$1" == "--inc" ]]; then
  inc_output_vol
elif [[ "$1" == "--dec" ]]; then
  dec_output_vol
elif [[ "$1" == "--toggle" ]]; then
  toggle_output
elif [[ "$1" == "--toggle-mic" ]]; then
  toggle_input
elif [[ "$1" == "--mic-inc" ]]; then
  increase_input_vol
elif [[ "$1" == "--mic-dec" ]]; then
  decrease_input_vol
else
  get_output_vol
fi
