#!/usr/bin/env bash
set -euo pipefail

# install_vncpasswd.sh
# Ensure a usable `vncpasswd` command is available on the system.
# Run this as root inside the dev container (the installer will invoke it).
#
# Behavior:
#  - If the system already has `vncpasswd` in PATH, do nothing.
#  - Otherwise, if `x11vnc` is installed, create a small wrapper at
#    `/usr/local/bin/vncpasswd` that implements -h and -f via `x11vnc -storepasswd`.
#  - If neither is available, print an error and exit non-zero.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[ERROR] Run as root to install or create vncpasswd" >&2
  exit 1
fi

if command -v vncpasswd >/dev/null 2>&1; then
  echo "[OK] vncpasswd already present: $(command -v vncpasswd)"
  exit 0
fi

if ! command -v x11vnc >/dev/null 2>&1; then
  echo "[ERROR] Neither vncpasswd nor x11vnc found. Please ensure x11vnc is installed or provide vncpasswd." >&2
  exit 1
fi

cat > /usr/local/bin/vncpasswd <<'WRAP'
#!/bin/sh
# vncpasswd wrapper (x11vnc backend)
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

chmod 0755 /usr/local/bin/vncpasswd
echo "[OK] Installed vncpasswd wrapper at /usr/local/bin/vncpasswd (x11vnc backend)."

exit 0
