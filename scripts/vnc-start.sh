#!/usr/bin/env bash
set -euo pipefail

# vnc-start.sh (TigerVNC / Xvnc only)
#
# Purpose:
#   Start a TigerVNC-managed Xvnc session and run ~/.vnc/xstartup to launch
#   a lightweight window manager and any programs defined there.
#
# Usage (inside container as app user):
#   $ VNC_PASSWORD='secret' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' \
#     /bin/bash /rails/scripts/vnc-start.sh

# Determine user home robustly: prefer $HOME, fall back to /home/rails if unset
USER_HOME="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6 || echo /home/rails)}"
VNC_DISPLAY_NUMBER="${VNC_DISPLAY_NUMBER:-1}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x800}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
VNC_PORT=$((5900 + VNC_DISPLAY_NUMBER))

VNC_PASS_FILE="${USER_HOME}/.vnc/passwd"

mkdir -p "${USER_HOME}/.vnc"
chmod 700 "${USER_HOME}/.vnc"

# Create VNC password file if missing or empty
if [[ ! -s "${VNC_PASS_FILE}" ]]; then
  if [[ -z "${VNC_PASSWORD}" ]]; then
    echo "[ERROR] VNC_PASSWORD must be provided on first run to create ${VNC_PASS_FILE}" >&2
    exit 1
  fi
  if ! command -v vncpasswd >/dev/null 2>&1; then
    echo "[ERROR] 'vncpasswd' not found. Please run the VNC installer as root: /rails/scripts/install-vnc-tigervnc.sh" >&2
    exit 1
  fi
  # Use discovered vncpasswd to generate the passwd file
  if echo "${VNC_PASSWORD}" | vncpasswd -f > "${VNC_PASS_FILE}" 2>/dev/null; then
    # Ensure file was created and is non-empty
    if [[ ! -s "${VNC_PASS_FILE}" ]]; then
      echo "[ERROR] vncpasswd did not produce a valid password file at ${VNC_PASS_FILE}" >&2
      exit 1
    fi
    chmod 600 "${VNC_PASS_FILE}"
  else
    echo "[ERROR] vncpasswd failed to create ${VNC_PASS_FILE}" >&2
    exit 1
  fi
fi

# Prepare ~/.vnc/xstartup by copying the repository template if present.
XSTARTUP="${USER_HOME}/.vnc/xstartup"
TEMPLATE="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)/xstartup.template"
if [[ -f "${TEMPLATE}" ]]; then
  cp "${TEMPLATE}" "${XSTARTUP}"
  chmod 0755 "${XSTARTUP}"
  echo "[INFO] Copied xstartup from template: ${TEMPLATE}"
else
  echo "[ERROR] xstartup template not found: ${TEMPLATE}" >&2
  echo "Please create or restore scripts/xstartup.template and re-run the start script." >&2
  exit 1
fi

# Kill any existing vncserver on this display to ensure a clean start
vncserver -kill :${VNC_DISPLAY_NUMBER} >/dev/null 2>&1 || true

echo "[INFO] Starting TigerVNC Xvnc on :${VNC_DISPLAY_NUMBER} (port ${VNC_PORT}) geometry=${VNC_GEOMETRY} depth=${VNC_DEPTH}"
vncserver :${VNC_DISPLAY_NUMBER} \
  -geometry ${VNC_GEOMETRY} \
  -depth ${VNC_DEPTH} \
  -rfbauth "${VNC_PASS_FILE}" \
  -localhost no

echo "[OK] vncserver started. Connect to port ${VNC_PORT} on the host (via compose port mapping)."
