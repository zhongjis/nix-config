if pmset -g ac | grep -q 'Family Code = 0x0000'; then # No battery (i.e. Mac Mini, Mac Pro, etc.)
    sketchybar \
        --set $NAME \
        icon.color="0xFFFFFFFF" \
        icon="󰚥" \
        label="AC"
else
    data=$(pmset -g batt)
    battery_percent=$(echo $data | grep -Eo "\d+%" | cut -d% -f1)
    charging=$(echo $data | grep 'AC Power')

    case "$battery_percent" in
        100) icon="󰁹" color=0xFFFFFFFF ;;
        9[0-9]) icon="󰂂" color=0xFFFFFFFF ;;
        8[0-9]) icon="󰂁" color=0xFFFFFFFF ;;
        7[0-9]) icon="󰂀" color=0xFFFFFFFF ;;
        6[0-9]) icon="󰁿" color=0xFFFFFFFF ;;
        5[0-9]) icon="󰁾" color=0xFFFFFFFF ;;
        4[0-9]) icon="󰁽" color=0xFFFFFFFF ;;
        3[0-9]) icon="󰁼" color=0xFFFFFFFF ;;
        2[0-9]) icon="󰁻" color=0xFFFFFFFF ;;
        1[0-9]) icon="󰁺" color=0xFFFFFFFF ;;
        *) icon="󰂃" color=0xFFFFFFFF ;;
    esac

    # if is charging
    if ! [ -z "$charging" ]; then
        icon="$icon 󰚥"
    fi

    sketchybar \
        --set $NAME \
        icon.color="$color" \
        icon="$icon" \
        label="$battery_percent%"
fi
