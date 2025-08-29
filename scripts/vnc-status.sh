#!/usr/bin/env bash
set -euo pipefail

# vnc-status.sh
VNC_DISPLAY_NUMBER="${VNC_DISPLAY_NUMBER:-1}"
USER_HOME="${HOME:-/home/rails}"

echo "== vncserver sessions =="
vncserver -list || echo "(no vncserver sessions)"

echo
echo "== Processes related to vnc/Xvnc/fluxbox =="
pgrep -a Xtigervnc || pgrep -a Xvnc || echo "(no Xvnc/Xtigervnc)"
pgrep -a vnc || true
pgrep -a fluxbox || echo "(no fluxbox)"

echo
echo "== xstartup log (if any) =="
ls -l "${USER_HOME}/.vnc" 2>/dev/null || true
tail -n 80 "${USER_HOME}/.vnc/$(hostname):${VNC_DISPLAY_NUMBER}.log" 2>/dev/null || true

echo
VNC_PORT=$((5900 + VNC_DISPLAY_NUMBER))
echo "Hint: connect with a TigerVNC client to 127.0.0.1:${VNC_PORT}."
