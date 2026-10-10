#!/usr/bin/env bash
# Grab one frame from the capture device, which is how the loop is closed.
#
#   ./capture.sh                 # writes shot-<timestamp>.png
#   ./capture.sh out.png
#   CAPTURE_DEV=/dev/video4 ./capture.sh
#
# Run scripts/capture-probe.sh first if you do not know which node to use or
# which formats it offers.
set -euo pipefail

DEV="${CAPTURE_DEV:-/dev/video0}"
SIZE="${CAPTURE_SIZE:-1920x1080}"
FORMAT="${CAPTURE_FORMAT:-mjpeg}"
SKIP="${CAPTURE_SKIP:-30}"
out="${1:-shot-$(date +%Y%m%d-%H%M%S).png}"

[ -e "$DEV" ] || { echo "no such capture device: $DEV" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found" >&2; exit 1; }

# -nostdin    so ffmpeg does not eat the caller's standard input
# select=gte  skip early frames, which are frequently malformed
# -update 1   tell the image muxer a single file is intended
ffmpeg -nostdin -loglevel error \
       -f v4l2 -input_format "$FORMAT" -video_size "$SIZE" -i "$DEV" \
       -vf "select=gte(n\,$SKIP)" -frames:v 1 -update 1 "$out"

echo "$out"
