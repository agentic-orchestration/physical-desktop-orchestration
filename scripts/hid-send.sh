#!/usr/bin/env bash
# Send one command to the running HID bridge through its control FIFO.
#
#   ./hid-send.sh status
#   ./hid-send.sh type "hello."
#   ./hid-send.sh key enter
#   ./hid-send.sh usage 06 ctrl        # ctrl-c
#   ./hid-send.sh move 40 -15
#   ./hid-send.sh click left
#   ./hid-send.sh scroll -3
#
# The FIFO is root-owned because the service is. Set HID_SUDO=1 to wrap the
# write in sudo; note that sudo cannot read a password from stdin here, since
# stdin carries the command, so use a cached credential or a NOPASSWD rule
# scoped to this one write.
set -euo pipefail

FIFO="${HID_FIFO:-/run/hid-bridge/control}"
[ $# -gt 0 ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

if [ "$1" = "type" ]; then
    shift
    line="type $*"
else
    line="$*"
fi

[ -p "$FIFO" ] || { echo "no control fifo at $FIFO; is the service running?" >&2; exit 1; }

if [ "${HID_SUDO:-0}" = "1" ]; then
    printf '%s\n' "$line" | sudo tee "$FIFO" >/dev/null
else
    printf '%s\n' "$line" > "$FIFO"
fi
