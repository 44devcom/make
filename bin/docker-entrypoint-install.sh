#!/usr/bin/env bash
# Runs install.sh with components from INSTALL_MODULES (space-separated), then exec's CMD.
# Skips install when the image was baked (--install.sh at docker build) and INSTALL_MODULES matches BAKED_INSTALL_MODULES.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Compose can override entrypoint and drop image CMD. Default to sleep infinity.
if [[ $# -eq 0 ]]; then
  set -- sleep infinity
fi

# Faster dpkg unpack in containers (safe for ephemeral images; skip with DPKG_UNSAFE_IO=0).
if [[ "${DPKG_UNSAFE_IO:-1}" == "1" ]] && [[ -w /etc/dpkg/dpkg.cfg.d ]]; then
  printf 'force-unsafe-io\n' >/etc/dpkg/dpkg.cfg.d/01unsafe-io
fi

# Collapse whitespace for stable comparison with BAKED_INSTALL_MODULES.
_collapse_ws() {
  local s=$1
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s" | tr -s '[:space:]' ' '
}

read -r -a mods <<< "${INSTALL_MODULES:-tools}"
if [[ ${#mods[@]} -eq 0 ]]; then
  mods=(tools)
fi

run_install=1
if [[ -f /var/lib/.make-install-baked ]] && [[ "${FORCE_RUNTIME_INSTALL:-0}" != "1" ]]; then
  baked_raw="${BAKED_INSTALL_MODULES:-}"
  wanted_raw="${INSTALL_MODULES:-tools}"
  if [[ -n "$baked_raw" ]]; then
    baked_norm="$(_collapse_ws "$baked_raw")"
    wanted_norm="$(_collapse_ws "$wanted_raw")"
    if [[ "$wanted_norm" == "$baked_norm" ]]; then
      run_install=0
    fi
  fi
fi

if [[ "$run_install" -eq 1 ]]; then
  /install/bin/install.sh "${mods[@]}"
fi

# Optional runtime user provisioning from env.
# See bin/lib/useradd.sh for USERADD_* format.
if [[ -n "${USERADD_USERS:-}" ]]; then
  bash /install/bin/lib/useradd.sh
fi

# Containers have no systemd; systemctl restart xrdp in lib installers does not leave a listener.
if [[ -x /usr/sbin/xrdp && "${START_XRDP:-1}" != "0" ]]; then
  if [[ "${1-}" == "sleep" && "${2-}" == "infinity" ]]; then
    exec bash /install/bin/docker-start-xrdp.sh
  fi
fi

exec "$@"
