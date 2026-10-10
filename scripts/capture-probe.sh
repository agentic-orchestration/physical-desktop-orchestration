#!/usr/bin/env bash
# List capture devices and the formats each one actually supports.
#
# One capture stick often exposes several /dev/video* nodes while only some
# deliver frames, and asking for a format the hardware does not produce
# natively drops the frame rate to single digits.
set -euo pipefail

if ! command -v v4l2-ctl >/dev/null; then
    echo "v4l2-ctl not found (package is usually v4l-utils)" >&2
    exit 1
fi

v4l2-ctl --list-devices || true
echo
for dev in /dev/video*; do
    [ -e "$dev" ] || continue
    echo "=== $dev ==="
    v4l2-ctl -d "$dev" --list-formats-ext 2>/dev/null | sed -n '1,40p' \
        || echo "  (no format information)"
    echo
done
