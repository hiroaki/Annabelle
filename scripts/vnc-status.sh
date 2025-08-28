#!/usr/bin/env bash
set -euo pipefail

# vnc-status.sh
# Quick status for Xvfb/x11vnc/Fluxbox and related artifacts.

VNC_DISPLAY="${VNC_DISPLAY:-:1}"
DISPLAY_NUM="${VNC_DISPLAY#:}"
USER_HOME="${HOME:-/home/rails}"

echo "== Processes =="
pgrep -a Xvfb || echo "(no Xvfb)"
pgrep -a x11vnc || echo "(no x11vnc)"
pgrep -a fluxbox || echo "(no fluxbox)"

echo
echo "== Sockets/locks =="
ls -l "/tmp/.X${DISPLAY_NUM}-lock" 2>/dev/null || echo "/tmp/.X${DISPLAY_NUM}-lock (absent)"
ls -l "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || echo "/tmp/.X11-unix/X${DISPLAY_NUM} (absent)"

echo
echo "== x11vnc log (tail) =="
tail -n 80 "${USER_HOME}/.vnc/x11vnc.log" 2>/dev/null || echo "(no log)"

echo
if command -v ss >/dev/null 2>&1; then
  echo "== Listening ports (grep 5901) =="
  ss -ltnp | grep 5901 || echo "(no listener on 5901)"
else
  echo "(tip) 'ss' not found; to check listener: nc -vz 127.0.0.1 5901 (from host)"
fi

echo
echo "Hint: connect with a VNC viewer to 127.0.0.1:5901 (or host:1)."
