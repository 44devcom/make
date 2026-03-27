#!/usr/bin/env bash
# shellcheck shell=bash
# Google Chrome stable (AMD64 deb). Sourced from install.sh.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file from install.sh; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_chrome_loaded:-}" ]]; then
  return 0
fi
_bin_lib_chrome_loaded=1

bin_install_chrome() {
  local deb_url deb
  deb_url='https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
  deb="$(mktemp "${TMPDIR:-/tmp}/chrome.XXXXXX.deb")"
  wget -qO "$deb" -- "$deb_url"
  sudo apt-get install -y "$deb"
  rm -f "$deb"
  sudo apt-get install -y preload
  sudo apt-get autoremove -y
  sudo apt-get clean
}
