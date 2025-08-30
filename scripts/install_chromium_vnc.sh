#!/usr/bin/env bash

# install_chromium_vnc.sh (DEPRECATED: use split installers)
#
# Purpose:
#   Install a developer-focused GUI stack inside the running development container:
#     - Chromium (browser)
#     - TigerVNC (Xvnc via `vncserver`)
#     - Fluxbox (lightweight window manager)
#     - autocutsel (clipboard sync) and useful fonts
#
# Effects:
#   - Installs packages required to run Chromium under an Xvnc session created by
#     TigerVNC. The script will also create a small `vncpasswd` wrapper using
#     `x11vnc -storepasswd` when the platform package does not supply `vncpasswd`.
#
# Preconditions / Notes:
#   - This script must be run as root inside the running dev container.
#     Example (from host):
#
#       docker compose exec --user root web bash -lc \
#         "/bin/bash /rails/scripts/install_chromium_vnc.sh"
#
#   - The repository's design intentionally installs Chromium/VNC at container
#     runtime (not at image build time). Ensure the container is running before
#     executing this script.
#
#   - The script runs apt-get in non-interactive mode and attempts to handle
#     Debian packaging differences (e.g. missing `vncpasswd` on some arches).
#
#   - After install, start VNC as the application user (see `scripts/vnc-start.sh`).
#
# Replacement scripts:
#   - Browser only: /rails/scripts/browser-install-chromium.sh
#   - VNC only    : /rails/scripts/vnc-install-tigervnc.sh
#
# Usage summary (legacy, still works):
#   1) Run the installer as root (inside the container).
#   2) As the application user (rails), run `scripts/vnc-start.sh` with
#      environment variables `VNC_PASSWORD`, `VNC_DISPLAY_NUMBER`, `VNC_GEOMETRY`.
#
# Example (install -> start):
#   docker compose exec --user root web bash -lc \
#     "/bin/bash /rails/scripts/install_chromium_vnc.sh"
#
#   docker compose exec web bash -lc \
#     "VNC_PASSWORD='secret' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' \
#       /bin/bash /rails/scripts/vnc-start.sh"

set -euo pipefail

# install_chromium_vnc.sh
# Root-only: install Chromium + TigerVNC (Xvnc) + Fluxbox (light WM) and fonts inside the container.

echo "[WARN] install_chromium_vnc.sh is deprecated." >&2
echo "[WARN] Use browser-install-chromium.sh and vnc-install-tigervnc.sh separately." >&2

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root inside the container (docker compose exec --user root web ...)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --no-install-recommends -y \
  chromium \
  tigervnc-standalone-server \
  tigervnc-common \
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
# Xvnc will create sockets under /tmp/.X11-unix if needed; ensure the directory exists and perms are permissive.
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix || true
chmod 1777 /tmp/.X11-unix || true


# Clean up APT caches to keep image smaller at runtime
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] Chromium + TigerVNC (Xvnc) + Fluxbox installed."
# Ensure a usable `vncpasswd` tool exists. This helper will create a wrapper
# around x11vnc -storepasswd if necessary.
if [[ -x "/rails/scripts/install_vncpasswd.sh" ]]; then
  /bin/bash /rails/scripts/install_vncpasswd.sh || {
    echo "[WARN] install_vncpasswd.sh failed; you may need to install x11vnc or vncpasswd manually." >&2
  }
else
  echo "[NOTE] install_vncpasswd.sh not present; ensure 'vncpasswd' is available for vnc-start.sh to work." >&2
fi
