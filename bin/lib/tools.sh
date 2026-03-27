#!/usr/bin/env bash
# shellcheck shell=bash
# CLI and general utilities (APT). Sourced from install.sh.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file from install.sh; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_tools_loaded:-}" ]]; then
  return 0
fi
_bin_lib_tools_loaded=1

bin_install_tools() {
  sudo apt-get install -y \
    mc git htop make rsync telnet dialog whiptail rtkit colord
}
