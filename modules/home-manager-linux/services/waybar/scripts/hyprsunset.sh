#!/usr/bin/env bash
# Waybar hyprsunset status script
# Shows current status and allows toggling

get_status() {
  if systemctl --user is-active --quiet hyprsunset.service; then
    # Service is running (blue light filter active)
    echo '{"text": "ON", "tooltip": "Hyprsunset: Active (blue light filter on)", "class": "active"}'
  else
    # Service is stopped (no filter)
    echo '{"text": "OFF", "tooltip": "Hyprsunset: Inactive (blue light filter off)", "class": "inactive"}'
  fi
}

toggle() {
  if systemctl --user is-active --quiet hyprsunset.service; then
    systemctl --user stop hyprsunset.service
  else
    systemctl --user start hyprsunset.service
  fi
}

case "$1" in
  --toggle)
    toggle
    ;;
  *)
    get_status
    ;;
esac
