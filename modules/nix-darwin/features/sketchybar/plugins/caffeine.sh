if pgrep -q 'caffeinate'; then
    sketchybar --set $NAME icon="󰅶"
else
    sketchybar --set $NAME icon="󰛊"
fi
