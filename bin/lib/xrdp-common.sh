#!/usr/bin/env bash
# shellcheck shell=bash
# Shared XRDP-related tuning (sysctl). Sourced by xrdp*_ installers.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_xrdp_common_loaded:-}" ]]; then
  return 0
fi
_bin_lib_xrdp_common_loaded=1

bin_lib_sysctl_xrdp_tuning() {
  echo "vm.max_map_count=524288" | sudo tee /etc/sysctl.d/99-custom.conf >/dev/null
  echo "net.core.wmem_max=8388608" | sudo tee -a /etc/sysctl.d/99-custom.conf >/dev/null
  sudo sysctl --system
}
