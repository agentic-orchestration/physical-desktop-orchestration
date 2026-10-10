#!/usr/bin/env bash
# Open a short pairing window on the bridge, then close it again.
#
# The client side of pairing is manual by design: confirm in that machine's own
# Bluetooth settings while this window is open. Nothing here can answer that
# dialog for you.
#
#   ./pair-window.sh [seconds]
set -euo pipefail

SECONDS_OPEN="${1:-${HID_PAIR_WINDOW:-120}}"
command -v bluetoothctl >/dev/null || { echo "bluetoothctl not found" >&2; exit 1; }

cleanup() {
    bluetoothctl discoverable off >/dev/null 2>&1 || true
    bluetoothctl pairable off     >/dev/null 2>&1 || true
    echo "pairing window closed"
}
trap cleanup EXIT INT TERM

bluetoothctl power on        >/dev/null
bluetoothctl pairable on     >/dev/null
bluetoothctl discoverable on >/dev/null
echo "pairing window open for ${SECONDS_OPEN}s"
echo "now: on the client, open its Bluetooth settings, pick this device, confirm"
sleep "$SECONDS_OPEN"
