#!/usr/bin/env bash
# Apply the three system-level changes a HID bridge host needs.
#
#   1. start the Bluetooth daemon without its `input` and `hostname` plugins
#   2. set the adapter's Class of Device to a keyboard
#   3. give the adapter a recognisable name
#
# This is deliberately interactive, because step 1 is not free: it stops the
# machine using Bluetooth keyboards and mice of its own, for every adapter.
# Pass --yes to skip the prompt in a provisioning run.
#
# Demonstration script. Read it before running it as root.
set -euo pipefail

NAME="${HID_NAME:-ExampleKbdBridge}"
CLASS="${HID_CLASS:-0x000540}"        # Peripheral major, keyboard minor
MAIN_CONF="${HID_MAIN_CONF:-/etc/bluetooth/main.conf}"
STAMP="$(date +%Y%m%d-%H%M%S)"
assume_yes=0
[ "${1:-}" = "--yes" ] && assume_yes=1

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
command -v systemctl >/dev/null || { echo "this script assumes systemd" >&2; exit 1; }

# Take the daemon path from the running unit rather than guessing: it differs
# between distributions.
daemon=$(systemctl show -p ExecStart --value bluetooth \
         | sed -n 's/.*path=\([^ ;]*\).*/\1/p' | head -1)
[ -n "$daemon" ] || { echo "could not read bluetoothd path from the unit" >&2; exit 1; }
echo "daemon:     $daemon"
echo "adapter:    name=$NAME class=$CLASS"
echo "main.conf:  $MAIN_CONF"
echo
echo "This disables Bluetooth input devices on this machine, daemon-wide."
if [ "$assume_yes" -eq 0 ]; then
    read -r -p "Continue? [y/N] " reply
    [ "$reply" = "y" ] || [ "$reply" = "Y" ] || { echo "aborted"; exit 1; }
fi

install -d -m 0755 /etc/systemd/system/bluetooth.service.d
cat > /etc/systemd/system/bluetooth.service.d/10-hid-bridge.conf <<CONF
# Added by setup-bridge.sh. Removing this file restores stock behaviour.
[Service]
ExecStart=
ExecStart=$daemon --noplugin=input,hostname
CONF
echo "wrote systemd drop-in"

if [ -f "$MAIN_CONF" ]; then
    cp -a "$MAIN_CONF" "$MAIN_CONF.bak-$STAMP"
    echo "backed up $MAIN_CONF to $MAIN_CONF.bak-$STAMP"
else
    install -d -m 0755 "$(dirname "$MAIN_CONF")"
    printf '[General]\n' > "$MAIN_CONF"
fi

set_key() {   # set_key <key> <value>, within the [General] section
    local key="$1" value="$2"
    if grep -qE "^[[:space:]]*#?[[:space:]]*$key[[:space:]]*=" "$MAIN_CONF"; then
        sed -i -E "s|^[[:space:]]*#?[[:space:]]*$key[[:space:]]*=.*|$key = $value|" "$MAIN_CONF"
    else
        sed -i "0,/^\[General\]/s//[General]\n$key = $value/" "$MAIN_CONF"
    fi
}
set_key Class "$CLASS"
set_key Name "$NAME"
set_key DiscoverableTimeout 180
echo "updated $MAIN_CONF"

systemctl daemon-reload
systemctl restart bluetooth
sleep 2

echo
echo "--- verify: the class below should read Peripheral/keyboard, not Computer"
if command -v btmgmt >/dev/null; then
    btmgmt info | sed -n '1,12p'
else
    echo "btmgmt not installed; check with your preferred tool"
fi
echo
echo "The controller merges service bits of its own into the class, so the"
echo "value reported back is longer than the one configured. That is expected."
