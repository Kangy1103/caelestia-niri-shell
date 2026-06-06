#!/usr/bin/env bash
# Created by Kangy w/ OpenCode AI Assistance
# Version: 1.4.0-20260606
#
# Reads idle.timeouts from system.json and launches swayidle.
# Entries with timeout: 0 are skipped.
# Restarts up to 5 times if swayidle crashes.

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-niri-shell/system.json"
MAX_RESTARTS=5
RESTART_COUNT=0

if ! command -v swayidle &>/dev/null; then
    notify-send -u critical "CNS: swayidle not installed" \
        "Install swayidle to enable idle lock: sudo pacman -S swayidle"
    exit 1
fi

start_swayidle() {
    local args=()

    if ! command -v jq &>/dev/null || [ ! -f "$CONFIG_FILE" ]; then
        args+=(timeout 1800 "qs -c caelestia-niri-shell ipc call lock lock")
        args+=(timeout 3600 "niri msg action power-off-monitors")
        args+=(resume "niri msg action power-on-monitors")
    else
        while read -r entry; do
            [ -z "$entry" ] && continue
            timeout=$(echo "$entry" | jq -r '.timeout // 0')
            [ "$timeout" -le 0 ] && continue

            action=$(echo "$entry" | jq -r '.idleAction // ""')
            [ -z "$action" ] && continue

            args+=(timeout "$timeout")

            case "$action" in
                lock)
                    args+=("qs -c caelestia-niri-shell ipc call lock lock")
                    ;;
                "dpms off")
                    args+=("niri msg action power-off-monitors")
                    ;;
                *)
                    arr=$(echo "$entry" | jq -r '.idleAction | if type == "array" then join(" ") else "" end')
                    if [ -n "$arr" ]; then
                        args+=("$arr")
                    else
                        args+=("$action")
                    fi
                    ;;
            esac

            ret=$(echo "$entry" | jq -r '.returnAction // ""')
            if [ -n "$ret" ] && [ "$ret" != "null" ]; then
                args+=(resume)
                case "$ret" in
                    "dpms on")
                        args+=("niri msg action power-on-monitors")
                        ;;
                    *)
                        retarr=$(echo "$entry" | jq -r '.returnAction | if type == "array" then join(" ") else "" end')
                        if [ -n "$retarr" ]; then
                            args+=("$retarr")
                        else
                            args+=("$ret")
                        fi
                        ;;
                esac
            fi
        done < <(jq -c '.general.idle.timeouts[]' "$CONFIG_FILE" 2>/dev/null)
    fi

    swayidle -w "${args[@]}"
}

while [ "$RESTART_COUNT" -lt "$MAX_RESTARTS" ]; do
    start_swayidle
    RESTART_COUNT=$((RESTART_COUNT + 1))
    sleep 2
done

notify-send -u critical "CNS: swayidle failed" \
    "swayidle crashed $MAX_RESTARTS times. Idle lock is disabled. Check the logs or restart the shell."
exit 1
