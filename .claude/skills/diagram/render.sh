#!/usr/bin/env bash
# render.sh — screenshot an HTML file to a retina PNG via headless Chrome.
# No Puppeteer, no test framework. Usage:
#   render.sh <input.html> <output.png> [width] [height] [bgHexAARRGGBB]
# Notes:
#   - Chrome's --screenshot captures the WINDOW viewport, not full page. There is no
#     full-page CLI flag, so size the window to your content and iterate the height to crop.
#   - Set bg to the page background so any extra window space is seamless (default white).
#   - @2x via --force-device-scale-factor for crisp text.
set -euo pipefail

HTML="${1:?need input.html}"; OUT="${2:?need output.png}"
W="${3:-1220}"; H="${4:-900}"; BG="${5:-ffffffff}"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || { echo "Chrome not found at: $CHROME (set \$CHROME)" >&2; exit 1; }

ABS="file://$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=2 --window-size="${W},${H}" \
  --default-background-color="$BG" \
  --screenshot="$OUT" "$ABS" 2>/dev/null

echo "rendered $OUT  (${W}x${H} @2x)"
