#!/usr/bin/env bash
set -euo pipefail

# install_chromium_vnc.sh
# Root-only: install Chromium + Xvfb + x11vnc + Fluxbox (light WM) and fonts inside the container.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root inside the container (docker compose exec --user root web ...)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --no-install-recommends -y \
  chromium \
  xvfb \
  x11vnc \
  fluxbox \
  autocutsel \
  fonts-liberation \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  ca-certificates \
  procps

# Provide common aliases for Chrome path expectations.
# Prefer Chromium packaged binary.
if [[ -x /usr/bin/chromium ]]; then
  ln -sf /usr/bin/chromium /usr/bin/google-chrome || true
  ln -sf /usr/bin/chromium /usr/bin/chromium-browser || true
fi

# Ensure rails user can start VNC and write logs
id rails &>/dev/null || useradd rails --create-home --shell /bin/bash

# Ensure X11 socket directory exists with proper ownership and permissions
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix


# Clean up APT caches to keep image smaller at runtime
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] Chromium + Xvfb + x11vnc + Fluxbox installed."
