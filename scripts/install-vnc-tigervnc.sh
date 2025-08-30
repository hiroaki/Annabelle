#!/usr/bin/env bash
set -euo pipefail

# vnc-install-tigervnc.sh
# Purpose:
#   Install TigerVNC server (Xvnc), a lightweight window manager (fluxbox),
#   clipboard sync (autocutsel), and utilities. Does NOT install Chromium.
#
# Usage (from host):
#   docker compose exec --user root web bash -lc \
#     "/bin/bash /rails/scripts/vnc-install-tigervnc.sh"
#
# After install (as user rails):
#   VNC_PASSWORD='secret' VNC_DISPLAY_NUMBER=1 /bin/bash /rails/scripts/vnc-start.sh

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root inside the container (docker compose exec --user root web ...)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --no-install-recommends -y \
  tigervnc-standalone-server \
  tigervnc-common \
  x11vnc \
  fluxbox \
  autocutsel \
  ca-certificates \
  procps

# Ensure rails user exists
id rails &>/dev/null || useradd rails --create-home --shell /bin/bash

# Ensure X11 socket directory exists
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix || true
chmod 1777 /tmp/.X11-unix || true

# Install vncpasswd wrapper if needed
if [[ -x "/rails/scripts/install-vncpasswd.sh" ]]; then
  /bin/bash /rails/scripts/install-vncpasswd.sh || {
    echo "[WARN] install-vncpasswd.sh failed; ensure vncpasswd is available." >&2
  }
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] TigerVNC + fluxbox installed. Start with scripts/vnc-start.sh as user 'rails'."
