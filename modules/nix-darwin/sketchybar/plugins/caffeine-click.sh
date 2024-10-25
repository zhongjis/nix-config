if pgrep -q 'caffeinate'; then
    killall caffeinate
    sketchybar --set $NAME icon="󰛊"
else
    caffeinate -d &
    disown
    sketchybar --set $NAME icon="󰅶"
fi
