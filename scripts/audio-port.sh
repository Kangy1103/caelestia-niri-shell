# Created by Kangy w/ OpenCode AI Assistance
# Version: 0.2.1-20260604

#!/bin/sh
# Switch PipeWire default sink output port (Line Out vs Headphones).
# Preserves current volume across port switches. Prints ACTIVE_PORT=<name>.
# Requires: pactl, wpctl, python3.

set -e
MODE="${1:-toggle}"
LINEOUT="${PORT_LINEOUT:-analog-output-lineout}"
HEADPHONES="${PORT_HEADPHONES:-analog-output-headphones}"

save_vol() {
	SINK="$(pactl get-default-sink)"
	wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'
}

restore_vol() {
	wpctl set-volume @DEFAULT_AUDIO_SINK@ "$1"
}

print_active() {
	SINK="$(pactl get-default-sink)"
	AP="$(pactl -f json list sinks | python3 -c '
import json, sys
sink = sys.argv[1]
data = json.load(sys.stdin)
for x in data:
    if x.get("name") == sink:
        print(x.get("active_port") or "")
        break
' "$SINK")"
	printf '%s\n' "ACTIVE_PORT=$AP"
}

notify() {
	case "$1" in
		*headphones*) notify-send -i headphones "Output: Headphones" -h string:x-canonical-private-synchronous:audio-port ;;
		*) notify-send -i audio-volume-high "Output: Line Out" -h string:x-canonical-private-synchronous:audio-port ;;
	esac
}

VOL=$(save_vol)

case "$MODE" in
	lineout)
		pactl set-sink-port @DEFAULT_SINK@ "$LINEOUT"
		AP=$(print_active)
		printf '%s\n' "$AP"
		notify "$AP"
		;;
	headphones)
		pactl set-sink-port @DEFAULT_SINK@ "$HEADPHONES"
		AP=$(print_active)
		printf '%s\n' "$AP"
		notify "$AP"
		;;
	toggle)
		SINK="$(pactl get-default-sink)"
		AP="$(pactl -f json list sinks | python3 -c '
import json, sys
sink = sys.argv[1]
data = json.load(sys.stdin)
for x in data:
    if x.get("name") == sink:
        print(x.get("active_port") or "")
        break
' "$SINK")"
		case "$AP" in
			*headphones*) pactl set-sink-port @DEFAULT_SINK@ "$LINEOUT" ;;
			*) pactl set-sink-port @DEFAULT_SINK@ "$HEADPHONES" ;;
		esac
		AP=$(print_active)
		printf '%s\n' "$AP"
		notify "$AP"
		;;
	*)
		echo "usage: $0 lineout|headphones|toggle" >&2
		exit 1
		;;
esac

# PipeWire may apply port-default volume asynchronously after port switch
sleep 0.05
restore_vol "$VOL"
