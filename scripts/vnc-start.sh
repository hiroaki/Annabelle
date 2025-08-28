#!/usr/bin/env bash
set -euo pipefail

# vnc-start.sh (TigerVNC / Xvnc only)
# Start a TigerVNC-managed Xvnc session and run ~/.vnc/xstartup to launch
# a lightweight window manager, clipboard sync, and Chromium. Intended to be
# run as the application user (rails).

USER_HOME="${HOME:-/home/rails}"
VNC_DISPLAY_NUMBER="${VNC_DISPLAY_NUMBER:-1}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x800}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
VNC_PORT=$((5900 + VNC_DISPLAY_NUMBER))

VNC_PASS_FILE="${USER_HOME}/.vnc/passwd"

mkdir -p "${USER_HOME}/.vnc"
chmod 700 "${USER_HOME}/.vnc"

# Create VNC password file if missing
# Create VNC password file if missing or empty
if [[ ! -s "${VNC_PASS_FILE}" ]]; then
  if [[ -z "${VNC_PASSWORD}" ]]; then
    echo "[ERROR] VNC_PASSWORD must be provided on first run to create ${VNC_PASS_FILE}" >&2
    exit 1
  fi
  # Use discovered vncpasswd to generate the passwd file
  if echo "${VNC_PASSWORD}" | vncpasswd -f > "${VNC_PASS_FILE}" 2>/dev/null; then
    :
  else
    echo "[WARN] vncpasswd pipeline failed; will try x11vnc -storepasswd directly." >&2
  fi
  # If file is empty after attempt, fall back to x11vnc
  if [[ ! -s "${VNC_PASS_FILE}" ]]; then
    if command -v x11vnc >/dev/null 2>&1; then
      x11vnc -storepasswd "${VNC_PASSWORD}" "${VNC_PASS_FILE}" >/dev/null 2>&1 || {
        echo "[ERROR] x11vnc -storepasswd failed to create ${VNC_PASS_FILE}" >&2
        exit 1
      }
    else
      echo "[ERROR] Could not create ${VNC_PASS_FILE}: neither vncpasswd worked nor x11vnc is available." >&2
      exit 1
    fi
  fi
  chmod 600 "${VNC_PASS_FILE}"
fi

# Prepare ~/.vnc/xstartup (always refresh to avoid stale content)
XSTARTUP="${USER_HOME}/.vnc/xstartup"
cat > "${XSTARTUP}" <<'EOF'
#!/bin/sh
export LANG=C
# start clipboard sync (PRIMARY and CLIPBOARD)
if command -v autocutsel >/dev/null 2>&1; then
  autocutsel -fork -selection PRIMARY || true
  autocutsel -fork -selection CLIPBOARD || true
fi
# start chromium to a blank page
if command -v chromium >/dev/null 2>&1; then
  chromium --no-sandbox --disable-gpu --disable-dev-shm-usage about:blank &
fi
# launch a window manager in background (if available)
if command -v fluxbox >/dev/null 2>&1; then
  fluxbox &
elif command -v openbox >/dev/null 2>&1; then
  openbox &
fi

# Always keep the session alive regardless of WM outcome
exec sh -c 'while :; do sleep 3600; done'
EOF
chmod +x "${XSTARTUP}"

# Kill any existing vncserver on this display to ensure a clean start
vncserver -kill :${VNC_DISPLAY_NUMBER} >/dev/null 2>&1 || true

echo "[INFO] Starting TigerVNC Xvnc on :${VNC_DISPLAY_NUMBER} (port ${VNC_PORT}) geometry=${VNC_GEOMETRY} depth=${VNC_DEPTH}"
vncserver :${VNC_DISPLAY_NUMBER} \
  -geometry ${VNC_GEOMETRY} \
  -depth ${VNC_DEPTH} \
  -rfbauth "${VNC_PASS_FILE}" \
  -localhost no

echo "[OK] vncserver started. Connect to port ${VNC_PORT} on the host (via compose port mapping)."

# Optional: keep this script in foreground by tailing the session log
if [[ "${VNC_BLOCK:-0}" = "1" ]]; then
  LOG_FILE="${USER_HOME}/.vnc/$(hostname):${VNC_DISPLAY_NUMBER}.log"
  echo "[INFO] Blocking mode enabled (VNC_BLOCK=1). Tailing ${LOG_FILE} (Ctrl-C to exit)."
  # Ensure log exists before tailing to avoid a race
  for i in $(seq 1 20); do
    [[ -f "${LOG_FILE}" ]] && break
    sleep 0.1
  done
  tail -f "${LOG_FILE}"
fi
