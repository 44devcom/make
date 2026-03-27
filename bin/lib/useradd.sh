#!/usr/bin/env bash
set -euo pipefail

# Add users from env configuration.
# Format:
#   USERADD_USERS="name:password:group1,group2;name2:password2:sudo"
# Optional vars:
#   USERADD_DEFAULT_SHELL (default: /bin/bash)
#   USERADD_DEFAULT_GROUPS (default: empty)
#   USERADD_DEFAULT_PASSWORD (default: empty; required per-user if not set)
#
# Example:
#   USERADD_USERS="junior:Adm1234#:docker,sudo;dev:Dev123!:sudo"

USERADD_DEFAULT_SHELL="${USERADD_DEFAULT_SHELL:-/bin/bash}"
USERADD_DEFAULT_GROUPS="${USERADD_DEFAULT_GROUPS:-}"
USERADD_DEFAULT_PASSWORD="${USERADD_DEFAULT_PASSWORD:-}"
USERADD_USERS="${USERADD_USERS:-}"

if [[ -z "${USERADD_USERS}" ]]; then
  echo "useradd.sh: USERADD_USERS is empty; nothing to do."
  exit 0
fi

ensure_group_exists() {
  local group="$1"
  [[ -z "$group" ]] && return 0
  if ! getent group "$group" >/dev/null 2>&1; then
    sudo groupadd "$group"
  fi
}

add_or_update_user() {
  local username="$1"
  local password="$2"
  local groups="$3"

  if [[ -z "$username" ]]; then
    return 0
  fi

  if ! id -u "$username" >/dev/null 2>&1; then
    sudo useradd -m -s "$USERADD_DEFAULT_SHELL" "$username"
  fi

  if [[ -n "$password" ]]; then
    echo "${username}:${password}" | sudo chpasswd
  fi

  if [[ -n "$groups" ]]; then
    local group
    IFS=',' read -r -a _group_list <<<"$groups"
    for group in "${_group_list[@]}"; do
      # trim surrounding spaces
      group="${group#"${group%%[![:space:]]*}"}"
      group="${group%"${group##*[![:space:]]}"}"
      ensure_group_exists "$group"
      [[ -n "$group" ]] && sudo usermod -aG "$group" "$username"
    done
  fi
}

entries="$USERADD_USERS"
IFS=';' read -r -a _entries <<<"$entries"
for entry in "${_entries[@]}"; do
  [[ -z "$entry" ]] && continue

  # name:password:groups (password/groups optional)
  name="${entry%%:*}"
  rest="${entry#*:}"

  if [[ "$entry" == *:* ]]; then
    password="${rest%%:*}"
    if [[ "$rest" == *:* ]]; then
      groups="${rest#*:}"
    else
      groups="${USERADD_DEFAULT_GROUPS}"
    fi
  else
    password="${USERADD_DEFAULT_PASSWORD}"
    groups="${USERADD_DEFAULT_GROUPS}"
  fi

  [[ -z "$password" ]] && password="${USERADD_DEFAULT_PASSWORD}"
  [[ -z "$groups" ]] && groups="${USERADD_DEFAULT_GROUPS}"

  # trim surrounding spaces
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  password="${password#"${password%%[![:space:]]*}"}"
  password="${password%"${password##*[![:space:]]}"}"
  groups="${groups#"${groups%%[![:space:]]*}"}"
  groups="${groups%"${groups##*[![:space:]]}"}"

  add_or_update_user "$name" "$password" "$groups"
done