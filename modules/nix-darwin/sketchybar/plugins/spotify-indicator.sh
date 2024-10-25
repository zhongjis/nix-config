RUNNING="$(osascript -e 'if application "Spotify" is running then return 0')"
if [ $RUNNING != 0 ]; then
    RUNNING=1
fi
PLAYING=1
TRACK=""
ALBUM=""
ARTIST=""
if [[ $RUNNING -eq 0 ]]; then
    [[ "$(osascript -e 'if application "Spotify" is running then tell application "Spotify" to get player state')" == "playing" ]] && PLAYING=0
    TRACK="$(osascript -e 'tell application "Spotify" to get name of current track')"
    ARTIST="$(osascript -e 'tell application "Spotify" to get artist of current track')"
    ALBUM="$(osascript -e 'tell application "Spotify" to get album of current track')"
fi
if [[ -n "$TRACK" ]]; then
    sketchybar -m --set "$NAME" drawing=on
    [[ "$PLAYING" -eq 0 ]] && ICON=""
    [[ "$PLAYING" -eq 1 ]] && ICON=""
    if [ "$ARTIST" == "" ]; then
        sketchybar -m --set "$NAME" label="''${ICON} ''${TRACK} - ''${ALBUM}"
    else
        sketchybar -m --set "$NAME" label="''${ICON} ''${TRACK} - ''${ARTIST}"
    fi
else
    sketchybar -m --set "$NAME" label="" drawing=off
fi
