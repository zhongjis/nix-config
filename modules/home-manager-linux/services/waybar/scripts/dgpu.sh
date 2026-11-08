#!/usr/bin/env bash
# Waybar discrete GPU status script
# Prints usage and edge temperature as one JSON line every 2 seconds
# Never wakes the dGPU: sensors are read only while runtime PM reports it active

critical=85

# The dGPU is the AMD card that is not the boot VGA device
dev=""
for d in /sys/class/drm/card*/device; do
  [[ $(<"$d/vendor") == 0x1002 && $(<"$d/boot_vga") == 0 ]] && dev=$d && break
done

print_status() {
  # Icon background #d8a657 matches the CSS text color; #cc241d marks critical
  local bg="#d8a657" class="$2"
  [[ $class == critical ]] && bg="#cc241d"
  echo "{\"text\": \"<span fgcolor=\\\"#202020\\\" bgcolor=\\\"$bg\\\"> 󰢮 </span> $1\", \"class\": \"$class\"}"
}

while true; do
  if [[ -z $dev ]]; then
    print_status "n/a" off
  elif [[ $(<"$dev/power/runtime_status") != active ]]; then
    print_status "off" off
  else
    # Reads can still fail with EBUSY if the GPU suspends between the check and the read
    usage=$(cat "$dev/gpu_busy_percent" 2>/dev/null)
    temp=$(cat "$dev"/hwmon/hwmon*/temp1_input 2>/dev/null)
    if [[ -n $usage && -n $temp ]]; then
      temp=$((temp / 1000))
      class=normal
      ((temp >= critical)) && class=critical
      print_status "$usage% ${temp}°C" "$class"
    else
      print_status "off" off
    fi
  fi
  sleep 2
done
