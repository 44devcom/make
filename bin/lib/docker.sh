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
  # Debian's docker-compose .deb and Docker's docker-compose-plugin both own
  # /usr/libexec/docker/cli-plugins/docker-compose — remove the distro package first.
  if dpkg-query -W -f='${Status}' docker-compose 2>/dev/null | grep -q 'ok installed'; then
    sudo apt-get remove -y docker-compose
  fi
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Docker: Debian 13 slim + installer + limits — Dockerfile (root), examples/compose-resources.yaml, examples/.env.example.

  if ! getent group docker >/dev/null; then
    sudo groupadd docker
  fi
  sudo usermod -aG docker "$u"
}
