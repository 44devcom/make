#!/usr/bin/env bash
# Start xrdp without systemd (container). xrdp-sesman daemons; xrdp stays foreground for PID 1.
set -euo pipefail

# Default sesman.ini disallows root; this image installs ~/.xsession as root.
if [[ "${XRDP_ALLOW_ROOT:-1}" == "1" ]] && [[ -f /etc/xrdp/sesman.ini ]]; then
  if grep -q '^AllowRootLogin=' /etc/xrdp/sesman.ini; then
    sed -i 's/^AllowRootLogin=.*/AllowRootLogin=true/' /etc/xrdp/sesman.ini
  fi
fi

if [[ -n "${XRDP_ROOT_PASSWORD:-}" ]]; then
  echo "root:${XRDP_ROOT_PASSWORD}" | chpasswd
fi

mkdir -p /var/run/xrdp /run/xrdp
rm -f /var/run/xrdp/xrdp-sesman.pid /tmp/.X*-lock 2>/dev/null || true

/usr/sbin/xrdp-sesman --kill 2>/dev/null || true

if [[ "${START_SYSTEM_DBUS:-1}" == "1" ]]; then
  mkdir -p /run/dbus
  if ! dbus-send --system --dest=org.freedesktop.DBus --print-reply /org/freedesktop/DBus org.freedesktop.DBus.GetId >/dev/null 2>&1; then
    dbus-daemon --system --fork 2>/dev/null || true
  fi
fi

/usr/sbin/xrdp-sesman
# sesman forks; give it a moment before xrdp connects
sleep 1
exec /usr/sbin/xrdp -n
