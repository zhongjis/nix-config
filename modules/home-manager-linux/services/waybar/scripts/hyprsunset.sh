#!/usr/bin/env bash
# Waybar hyprsunset status script
# Shows current status and allows toggling

get_status() {
  if systemctl --user is-active --quiet hyprsunset.service; then
    # Service is running (blue light filter active)
    # Color #7da389 matches the CSS text color for active state
    echo '{"text": "<span fgcolor=\"#202020\" bgcolor=\"#7da389\"> 󰖨 </span> ON", "tooltip": "Hyprsunset: Active (click to disable)", "class": "active"}'
  else
    # Service is stopped (no filter)
    # Color #ea6962 (red) matches the CSS text color for inactive state (same as muted)
    echo '{"text": "<span fgcolor=\"#202020\" bgcolor=\"#ea6962\"> 󰖨 </span> OFF", "tooltip": "Hyprsunset: Inactive (click to enable)", "class": "inactive"}'
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
