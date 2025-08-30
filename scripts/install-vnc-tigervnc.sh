#!/usr/bin/env bash
set -euo pipefail

# install-vnc-tigervnc.sh
#
# Purpose:
#   Install TigerVNC server (Xvnc), a lightweight window manager (fluxbox),
#   clipboard sync (autocutsel), and utilities.
#
# Usage:
#   Run inside the container as root
#   # docker compose exec --user root web bash -lc "/bin/bash /rails/scripts/install-vnc-tigervnc.sh"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root inside the container (docker compose exec --user root web ...)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --no-install-recommends -y \
  tigervnc-standalone-server \
  tigervnc-common \
  tigervnc-tools \
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

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] TigerVNC + fluxbox installed. Start with scripts/vnc-start.sh as user 'rails'."
