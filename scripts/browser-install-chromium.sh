#!/usr/bin/env bash
set -euo pipefail

# browser-install-chromium.sh
# Purpose:
#   Install Chromium browser and essential fonts inside the running dev container.
#   This is required for RSpec system specs using cuprite. Does NOT install VNC.
#
# Usage (from host):
#   docker compose exec --user root web bash -lc \
#     "/bin/bash /rails/scripts/browser-install-chromium.sh"
#
# Notes:
#   - Must be run as root inside the container.
#   - Creates convenient symlinks for chrome-compatible paths.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root inside the container (docker compose exec --user root web ...)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --no-install-recommends -y \
  chromium \
  fonts-liberation \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  ca-certificates \
  procps

# Provide common aliases for Chrome path expectations.
if [[ -x /usr/bin/chromium ]]; then
  ln -sf /usr/bin/chromium /usr/bin/google-chrome || true
  ln -sf /usr/bin/chromium /usr/bin/chromium-browser || true
fi

# Clean up APT caches
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] Chromium and fonts installed. You can run headless tests without VNC."
