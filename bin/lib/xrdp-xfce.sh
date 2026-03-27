#!/usr/bin/env bash
# shellcheck shell=bash
# XFCE desktop + XRDP (Xorg). Base tools live in tools.sh. Sourced from install.sh.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file from install.sh; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_xrdp_xfce_loaded:-}" ]]; then
  return 0
fi
_bin_lib_xrdp_xfce_loaded=1

_xrdp_xfce_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${_xrdp_xfce_lib_dir}/xrdp-common.sh"

bin_install_xrdp_xfce() {
  sudo apt-get install -y task-xfce-desktop dbus-x11

  sudo systemctl set-default graphical.target

  sudo apt-get install -y xrdp xorgxrdp

  sudo adduser xrdp ssl-cert || true

  sudo systemctl enable xrdp
  sudo systemctl restart xrdp

  bin_lib_sysctl_xrdp_tuning

  cat <<'EOF' | sudo tee /etc/xrdp/startwm.sh >/dev/null
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec startxfce4
EOF

  sudo chmod +x /etc/xrdp/startwm.sh

  cat <<'EOF' >~/.xsession
startxfce4
EOF

  sudo systemctl restart xrdp

  printf '%s\n' 'DONE: Connect via RDP (port 3389) — XFCE session'
}
