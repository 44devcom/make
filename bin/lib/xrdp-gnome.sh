#!/usr/bin/env bash
# shellcheck shell=bash
# GNOME desktop + XRDP (Xorg). Base tools live in tools.sh. Sourced from install.sh.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file from install.sh; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_xrdp_gnome_loaded:-}" ]]; then
  return 0
fi
_bin_lib_xrdp_gnome_loaded=1

_xrdp_gnome_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${_xrdp_gnome_lib_dir}/xrdp-common.sh"

bin_install_xrdp_gnome() {
  sudo apt-get install -y task-gnome-desktop gdm3 dbus-x11

  sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/daemon.conf || true
  sudo sed -i 's/^WaylandEnable=true/WaylandEnable=false/' /etc/gdm3/daemon.conf || true

  sudo systemctl enable gdm3
  sudo systemctl set-default graphical.target

  sudo apt-get install -y xrdp xorgxrdp

  sudo adduser xrdp ssl-cert || true

  sudo systemctl enable xrdp
  sudo systemctl restart xrdp

  bin_lib_sysctl_xrdp_tuning

  cat <<'EOF' | sudo tee /etc/xrdp/startwm.sh >/dev/null
#!/bin/sh
export XDG_CURRENT_DESKTOP=GNOME
export GNOME_SHELL_SESSION_MODE=gnome
export DESKTOP_SESSION=gnome

exec /etc/X11/Xsession
EOF

  sudo chmod +x /etc/xrdp/startwm.sh

  cat <<'EOF' >~/.xsession
gnome-session --session=gnome
EOF

  sudo systemctl restart gdm3
  sudo systemctl restart xrdp

  printf '%s\n' 'DONE: Connect via RDP (port 3389)'
}
