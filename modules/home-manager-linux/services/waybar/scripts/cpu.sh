#!/usr/bin/env bash
# Waybar CPU status script
# Prints usage and k10temp temperature as one JSON line every 2 seconds

critical=85

# k10temp is the AMD CPU sensor; hwmonN numbering changes across boots
temp_file=""
for h in /sys/class/hwmon/hwmon*; do
  [[ $(<"$h/name") == k10temp ]] && temp_file="$h/temp1_input" && break
done

print_status() {
  # Icon background #e78a4e matches the CSS text color; #cc241d marks critical
  local bg="#e78a4e" class="normal"
  if (($2 >= critical)); then
    bg="#cc241d"
    class="critical"
  fi
  echo "{\"text\": \"<span fgcolor=\\\"#202020\\\" bgcolor=\\\"$bg\\\">  </span> $1% $2°C\", \"class\": \"$class\"}"
}

read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
prev_idle=$((idle + iowait))

# Short first sample so the module appears right after Waybar starts
delay=0.25
while sleep "$delay"; do
  delay=2
  read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle=$((idle + iowait))
  usage=$((100 * (total - prev_total - idle + prev_idle) / (total - prev_total)))
  prev_total=$total
  prev_idle=$idle

  print_status "$usage" $(($(<"$temp_file") / 1000))
done
