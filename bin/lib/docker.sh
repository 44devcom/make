#!/usr/bin/env bash
# shellcheck shell=bash
# Docker Engine from Docker Inc. APT repo (Debian). Sourced from install.sh.

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s: source this file from install.sh; do not execute directly\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ -n "${_bin_lib_docker_loaded:-}" ]]; then
  return 0
fi
_bin_lib_docker_loaded=1

bin_install_docker() {
  local u
  u="${USER:-$(id -un)}"

  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # shellcheck disable=SC1091
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose

  if ! getent group docker >/dev/null; then
    sudo groupadd docker
  fi
  sudo usermod -aG docker "$u"
}
