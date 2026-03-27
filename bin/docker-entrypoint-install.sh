#!/usr/bin/env bash
# Runs install.sh with components from INSTALL_MODULES (space-separated), then exec's CMD.
set -euo pipefail

# Faster dpkg unpack in containers (safe for ephemeral images; skip with DPKG_UNSAFE_IO=0).
if [[ "${DPKG_UNSAFE_IO:-1}" == "1" ]] && [[ -w /etc/dpkg/dpkg.cfg.d ]]; then
  printf 'force-unsafe-io\n' >/etc/dpkg/dpkg.cfg.d/01unsafe-io
fi

read -r -a mods <<< "${INSTALL_MODULES:-tools}"
if [[ ${#mods[@]} -eq 0 ]]; then
  mods=(tools)
fi

/install/bin/install.sh "${mods[@]}"

# Containers have no systemd; systemctl restart xrdp in lib installers does not leave a listener.
if [[ -x /usr/sbin/xrdp && "${START_XRDP:-1}" != "0" ]]; then
  if [[ "${1-}" == "sleep" && "${2-}" == "infinity" ]]; then
    exec /install/bin/docker-start-xrdp.sh
  fi
fi

exec "$@"
