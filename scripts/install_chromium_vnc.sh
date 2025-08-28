#!/usr/bin/env bash
set -euo pipefail

# install_chromium_vnc.sh
# Root-only: install Chromium + TigerVNC (Xvnc) + Fluxbox (light WM) and fonts inside the container.

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

# Provide a vncpasswd wrapper if not present (use x11vnc -storepasswd under the hood)
if ! command -v vncpasswd >/dev/null 2>&1; then
  if command -v x11vnc >/dev/null 2>&1; then
    cat > /usr/local/bin/vncpasswd <<'WRAP'
#!/bin/sh
# Minimal wrapper to emulate `vncpasswd -f` using x11vnc's storepasswd.
# Usage in our scripts: echo "$PASS" | vncpasswd -f > ~/.vnc/passwd
case "$1" in
  -h|--help)
    echo "vncpasswd wrapper (x11vnc backend)"
    echo "Usage: echo 'secret' | vncpasswd -f > ~/.vnc/passwd"
    echo "Interactive mode: x11vnc -storepasswd"
    exit 0
    ;;
  -f)
  # read password from stdin and write the hashed passfile to stdout
  exec x11vnc -storepasswd - -
    ;;
  *)
  # interactive fallback (prompts and writes to ~/.vnc/passwd)
  exec x11vnc -storepasswd
    ;;
esac
WRAP
    chmod +x /usr/local/bin/vncpasswd
    echo "[OK] Installed vncpasswd wrapper via x11vnc -storepasswd."
  else
    echo "[ERROR] Neither vncpasswd nor x11vnc is available; cannot prepare VNC password tool." >&2
    exit 1
  fi
fi

# If a vncpasswd wrapper already exists and is our x11vnc-based script, refresh it to the latest version
if command -v vncpasswd >/dev/null 2>&1; then
  VP="$(command -v vncpasswd)"
  if [ "$VP" = "/usr/local/bin/vncpasswd" ] && grep -q "x11vnc -storepasswd" "$VP" 2>/dev/null; then
    cat > /usr/local/bin/vncpasswd <<'WRAP'
#!/bin/sh
# vncpasswd wrapper (x11vnc backend)
# Supports:
#   -h|--help : show help and exit 0
#   -f        : read password from stdin, write hashed to stdout
#   (default) : interactive prompt writing to ~/.vnc/passwd
case "$1" in
  -h|--help)
    echo "vncpasswd wrapper (x11vnc backend)"
    echo "Usage: echo 'secret' | vncpasswd -f > ~/.vnc/passwd"
    echo "Interactive mode: x11vnc -storepasswd"
    exit 0
    ;;
  -f)
    exec x11vnc -storepasswd - -
    ;;
  *)
    exec x11vnc -storepasswd
    ;;
esac
WRAP
    chmod +x /usr/local/bin/vncpasswd
    echo "[OK] Refreshed vncpasswd wrapper." 
  fi
fi
