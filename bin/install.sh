#!/usr/bin/env bash
# Orchestrator: run selected bin/lib installers in order.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly script_dir
lib_dir="${script_dir}/lib"
readonly lib_dir

dry_run=0
components=()

usage() {
  printf 'Usage: %s [--dry-run] [--help] <component> [component ...]\n' "$(basename "$0")" >&2
  printf 'Run %s --help for component list.\n' "$(basename "$0")" >&2
  exit 2
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--help] <component> [component ...]

Run one or more host setup modules from ${lib_dir}/ in the order given.

Options:
  --dry-run   Print planned actions only (no sudo, no installs)
  --help, -h  Show this help

Components:
  tools        CLI utilities (mc, git, htop, make, rsync, dialog, whiptail, ...)
  chrome       Google Chrome stable (amd64 deb) and preload
  docker       Docker Engine from Docker APT repository
  xrdp-gnome   GNOME desktop, GDM (Xorg), XRDP, sysctl tuning
  xrdp-xfce    XFCE desktop, XRDP, sysctl tuning

Example:
  $(basename "$0") tools docker
  $(basename "$0") --dry-run xrdp-xfce
EOF
}

is_known_component() {
  local name=$1
  case $name in
    tools | chrome | docker | xrdp-gnome | xrdp-xfce) return 0 ;;
    *) return 1 ;;
  esac
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage
  fi
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        dry_run=1
        shift
        ;;
      --help | -h)
        show_help
        exit 0
        ;;
      -*)
        printf 'Unknown option: %s\n' "$1" >&2
        usage
        ;;
      *)
        components+=("$1")
        shift
        ;;
    esac
  done
  if [[ ${#components[@]} -eq 0 ]]; then
    printf 'No components specified.\n' >&2
    usage
  fi
  local c
  for c in "${components[@]}"; do
    if ! is_known_component "$c"; then
      printf 'Unknown component: %s\n' "$c" >&2
      printf 'Valid: tools chrome docker xrdp-gnome xrdp-xfce\n' >&2
      exit 2
    fi
  done
}

source_libs() {
  # Order-independent; each lib guards double-load.
  # shellcheck source=lib/tools.sh
  source "${lib_dir}/tools.sh"
  # shellcheck source=lib/chrome.sh
  source "${lib_dir}/chrome.sh"
  # shellcheck source=lib/docker.sh
  source "${lib_dir}/docker.sh"
  # shellcheck source=lib/xrdp-gnome.sh
  source "${lib_dir}/xrdp-gnome.sh"
  # shellcheck source=lib/xrdp-xfce.sh
  source "${lib_dir}/xrdp-xfce.sh"
}

dry_run_tools() {
  printf '[dry-run] tools: apt-get install -y mc git htop make rsync telnet dialog whiptail rtkit colord\n'
}

dry_run_chrome() {
  printf '[dry-run] chrome: wget Google Chrome .deb, apt install, preload, autoremove, clean\n'
}

dry_run_docker() {
  printf '[dry-run] docker: add Docker APT repo, apt-get update, install docker-ce stack, docker group + usermod\n'
}

dry_run_xrdp_gnome() {
  printf '[dry-run] xrdp-gnome: task-gnome-desktop gdm3, Wayland off, xrdp xorgxrdp, startwm.sh, ~/.xsession, sysctl tuning\n'
}

dry_run_xrdp_xfce() {
  printf '[dry-run] xrdp-xfce: task-xfce-desktop, xrdp xorgxrdp, startwm.sh (startxfce4), ~/.xsession, sysctl tuning\n'
}

run_one() {
  local name=$1
  if [[ "$dry_run" -eq 1 ]]; then
    case $name in
      tools) dry_run_tools ;;
      chrome) dry_run_chrome ;;
      docker) dry_run_docker ;;
      xrdp-gnome) dry_run_xrdp_gnome ;;
      xrdp-xfce) dry_run_xrdp_xfce ;;
    esac
    return 0
  fi
  case $name in
    tools) bin_install_tools ;;
    chrome) bin_install_chrome ;;
    docker) bin_install_docker ;;
    xrdp-gnome) bin_install_xrdp_gnome ;;
    xrdp-xfce) bin_install_xrdp_xfce ;;
  esac
}

main() {
  parse_args "$@"
  source_libs
  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] Planned components (%d): %s\n' "${#components[@]}" "${components[*]}"
  else
    sudo apt-get update
  fi
  local c
  for c in "${components[@]}"; do
    printf '=== %s ===\n' "$c"
    run_one "$c"
  done
}

main "$@"
