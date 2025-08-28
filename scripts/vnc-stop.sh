#!/usr/bin/env bash
set -euo pipefail

# vnc-stop.sh
# Stop x11vnc and Xvfb for the given DISPLAY (default :1).

VNC_DISPLAY="${VNC_DISPLAY:-:1}"
DISPLAY_NUM="${VNC_DISPLAY#:}"

# Stop x11vnc bound to this display
pkill -f "x11vnc .* -display ${VNC_DISPLAY}" >/dev/null 2>&1 || true
# Fallback: in case the pattern changed, kill any x11vnc owned by this user
pkill x11vnc >/dev/null 2>&1 || true

# Stop Xvfb for this display
pkill -f "Xvfb ${VNC_DISPLAY}" >/dev/null 2>&1 || true

# Give processes a moment to exit
sleep 0.2

# Clean up possible stale lock/socket files for this display
LOCK_FILE="/tmp/.X${DISPLAY_NUM}-lock"
SOCK_FILE="/tmp/.X11-unix/X${DISPLAY_NUM}"
[[ -f "${LOCK_FILE}" ]] && rm -f "${LOCK_FILE}" || true
[[ -S "${SOCK_FILE}" ]] && rm -f "${SOCK_FILE}" || true

echo "[OK] x11vnc/Xvfb stopped on ${VNC_DISPLAY}."
