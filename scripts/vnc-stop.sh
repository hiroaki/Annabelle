#!/usr/bin/env bash
set -euo pipefail

# vnc-stop.sh (TigerVNC)
VNC_DISPLAY_NUMBER="${VNC_DISPLAY_NUMBER:-1}"

# Kill the vncserver session for the display
vncserver -kill :${VNC_DISPLAY_NUMBER} >/dev/null 2>&1 || true

echo "[OK] vncserver on :${VNC_DISPLAY_NUMBER} killed (if it existed)."
