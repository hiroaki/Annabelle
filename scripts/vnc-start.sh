#!/usr/bin/env bash
set -euo pipefail

# vnc-start.sh
# Run as the application user (rails). Starts Xvfb on DISPLAY and x11vnc bound to it.
#
# What this script does (simple overview):
# 1) Reads environment variables:
#    - VNC_PASSWORD: Password for VNC (required on first run)
#    - VNC_DISPLAY:  X display number (default :1)
#    - VNC_GEOMETRY: Resolution like 1280x800 (default 1280x800)
#    - VNC_DEPTH:    Color depth (default 24)
# 2) Prepares ~/.vnc and stores a hashed VNC password for x11vnc.
# 3) Starts a virtual X server (Xvfb) on the given DISPLAY with the specified geometry/depth.
# 4) Launches a lightweight window manager (fluxbox) and Chromium inside that DISPLAY.
# 5) Starts x11vnc attached to that DISPLAY, listening on localhost:5901 so you can connect from your host.
#    Keyboard issues (e.g., CapsLock) are mitigated by default x11vnc options; override via X11VNC_OPTS.
#
# Usage examples:
#   VNC_PASSWORD='pass' /bin/bash /rails/scripts/vnc-start.sh
#   VNC_PASSWORD='pass' VNC_DISPLAY=':2' VNC_GEOMETRY='1440x900' /bin/bash /rails/scripts/vnc-start.sh
#
# To stop the session, run:
#   /bin/bash /rails/scripts/vnc-stop.sh

USER_HOME="${HOME:-/home/rails}"
VNC_DISPLAY="${VNC_DISPLAY:-:1}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x800}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PASSWORD="${VNC_PASSWORD:-}"

# Ensure .vnc directory exists with proper perms
mkdir -p "${USER_HOME}/.vnc"
chmod 700 "${USER_HOME}/.vnc"

# Create x11vnc password file
X11VNC_PASS_FILE="${USER_HOME}/.vnc/x11vnc.pass"
if [[ -f "${X11VNC_PASS_FILE}" ]]; then
  # Password file exists already. If VNC_PASSWORD is provided, update it; otherwise reuse existing.
  if [[ -n "${VNC_PASSWORD}" ]]; then
    x11vnc -storepasswd "${VNC_PASSWORD}" "${X11VNC_PASS_FILE}"
    chmod 600 "${X11VNC_PASS_FILE}"
  fi
else
  # First-time setup requires VNC_PASSWORD to create the password file.
  if [[ -z "${VNC_PASSWORD}" ]]; then
    echo "[ERROR] First-time setup: export VNC_PASSWORD to create ~/.vnc/x11vnc.pass." >&2
    exit 1
  fi
  x11vnc -storepasswd "${VNC_PASSWORD}" "${X11VNC_PASS_FILE}"
  chmod 600 "${X11VNC_PASS_FILE}"
fi

# Start Xvfb (idempotent)
export DISPLAY="${VNC_DISPLAY}"
export LANG=C
X_RES="${VNC_GEOMETRY%x*}"
Y_RES="${VNC_GEOMETRY#*x}"
DISPLAY_NUM="${DISPLAY#:}"
# Ensure X unix socket dir exists (non-root creation is fine, set sticky bit)
if [[ ! -d /tmp/.X11-unix ]]; then
  mkdir -p /tmp/.X11-unix
fi
# Fix owner/perm if needed (X expects root:root and sticky bit)
chown root:root /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Clean up potential stale X lock/socket files for this display if no Xvfb is running.
LOCK_FILE="/tmp/.X${DISPLAY_NUM}-lock"
SOCK_FILE="/tmp/.X11-unix/X${DISPLAY_NUM}"
if ! pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  [[ -f "${LOCK_FILE}" ]] && rm -f "${LOCK_FILE}" || true
  [[ -S "${SOCK_FILE}" ]] && rm -f "${SOCK_FILE}" || true
fi
if ! pgrep -f "Xvfb ${DISPLAY} .*${X_RES}x${Y_RES}x${VNC_DEPTH}" >/dev/null 2>&1; then
  # -ac disables access control (no xauth cookie needed). Keep -nolisten tcp for security.
  Xvfb "$DISPLAY" -screen 0 "${X_RES}x${Y_RES}x${VNC_DEPTH}" -nolisten tcp -ac &
  # wait for the X socket to appear
  for i in {1..30}; do
    [[ -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ]] && break
    sleep 0.2
  done
fi

# Verify Xvfb is up; if not, exit with a helpful error.
if [[ ! -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ]]; then
  echo "[ERROR] Xvfb did not start on ${DISPLAY}. Try running vnc-stop and then vnc-start again. If it persists, remove stale /tmp/.X${DISPLAY_NUM}-lock." >&2
  exit 1
fi

# Kill previous session apps on this user (best-effort)
pkill -f "\bfluxbox\b" >/dev/null 2>&1 || true
pkill -f "\bchromium\b" >/dev/null 2>&1 || true
pkill -f "\bgoogle-chrome\b" >/dev/null 2>&1 || true

# Prepare minimal Fluxbox config to avoid wallpaper helper dialog
FLUX_DIR="${USER_HOME}/.fluxbox"
FLUX_INIT="${FLUX_DIR}/init"
mkdir -p "${FLUX_DIR}"
if [[ ! -f "${FLUX_INIT}" ]]; then
  cat > "${FLUX_INIT}" <<'EOF'
session.screen0.rootCommand: fbsetroot -solid grey
EOF
else
  if ! grep -q '^session.screen0.rootCommand:' "${FLUX_INIT}" 2>/dev/null; then
    echo 'session.screen0.rootCommand: fbsetroot -solid grey' >> "${FLUX_INIT}"
  fi
fi

# Start a simple session: fluxbox, chromium
(
  sleep 0.2
  if command -v fluxbox >/dev/null 2>&1; then
    fluxbox &
  fi
  sleep 0.5
  # Start clipboard sync between X PRIMARY/CLIPBOARD and VNC clients
  if command -v autocutsel >/dev/null 2>&1; then
    autocutsel -fork -selection PRIMARY || true
    autocutsel -fork -selection CLIPBOARD || true
  fi
  if command -v chromium >/dev/null 2>&1; then
    chromium --no-sandbox --disable-gpu --disable-dev-shm-usage about:blank &
  elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome --no-sandbox --disable-gpu --disable-dev-shm-usage about:blank &
  fi
) &

# Kill any previous x11vnc on that display, then fallback to kill any leftover x11vnc
pkill -f "x11vnc .* -display ${DISPLAY}" >/dev/null 2>&1 || true
pkill x11vnc >/dev/null 2>&1 || true

# Start x11vnc bound to the DISPLAY; listen on all interfaces in the container
# (Host exposure is still limited by compose.override.yml mapping to 127.0.0.1)
LOG_DIR="${USER_HOME}/.vnc"
LOG_FILE="${LOG_DIR}/x11vnc.log"
mkdir -p "${LOG_DIR}"

# Default options to improve keyboard behavior and stability. You can override by exporting X11VNC_OPTS.
# Base opts (keyboard)
KB_OPTS="-capslock -clear_all -nomodtweak"
# Stability/perf opts (avoid SHM issues on Xvfb)
STAB_OPTS="-noxdamage -rfbwait 60000 -wait 5 -noshm"
# Allow override/append from env; if provided, use as-is. Otherwise combine defaults.
if [[ -n "${X11VNC_OPTS:-}" ]]; then
  EFFECTIVE_OPTS="${X11VNC_OPTS}"
else
  EFFECTIVE_OPTS="${KB_OPTS} ${STAB_OPTS}"
fi

# Note: we avoid '-nonfbs' since this x11vnc version doesn't support it; fixed size is enforced by Xvfb geometry.

if [[ "${VNC_DEBUG:-0}" = "1" ]]; then
  echo "[DEBUG] Starting x11vnc in foreground (verbose)." >&2
  x11vnc -rfbauth "${X11VNC_PASS_FILE}" -display "$DISPLAY" -rfbport 5901 -forever -shared -noipv6 -listen 0.0.0.0 -loop -o - -verbose ${EFFECTIVE_OPTS}
else
  x11vnc -rfbauth "${X11VNC_PASS_FILE}" -display "$DISPLAY" -rfbport 5901 -forever -shared -noipv6 -listen 0.0.0.0 -loop ${EFFECTIVE_OPTS} -bg -o "${LOG_FILE}" >/dev/null 2>&1 || true
fi

# Check if x11vnc is up; if not, print a hint
sleep 0.5
# Liveness check: look for any x11vnc process
if pgrep -x x11vnc >/dev/null 2>&1; then
  echo "[OK] x11vnc started on ${DISPLAY} (port 5901, listening on 0.0.0.0 in container)."
else
  echo "[ERROR] x11vnc failed to start. See ${LOG_FILE} (last lines):"
  tail -n 50 "${LOG_FILE}" 2>/dev/null || true
fi
