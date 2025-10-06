#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/home/kali/Documents/gertest"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run as root. Use: su - -c 'bash $0'" >&2
    exit 1
  fi
}

log() {
  echo "[INFO] $*"
}

install_prereqs() {
  log "Updating apt and installing prerequisites..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release
}

setup_docker_repo() {
  log "Setting up Docker APT repository (Debian bookworm for Kali)..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  local codename
  codename=$( . /etc/os-release; echo "${VERSION_CODENAME:-bookworm}" )
  if [ "$codename" = "kali-rolling" ]; then
    codename=bookworm
  fi

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${codename} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
}

install_docker() {
  log "Installing Docker Engine, CLI, Buildx, and Compose plugin..."
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

enable_service() {
  log "Enabling and starting Docker service..."
  systemctl enable --now docker
}

post_install() {
  log "Docker versions:"
  docker --version || true
  docker compose version || true
}

add_user_to_group() {
  local user_name="kali"
  if id "$user_name" >/dev/null 2>&1; then
    log "Adding user '$user_name' to docker group (you must re-login for it to take effect)."
    usermod -aG docker "$user_name" || true
  fi
}

bring_up_stack() {
  log "Building and starting Docker compose stack in $PROJECT_DIR ..."
  cd "$PROJECT_DIR"
  docker compose build
  docker compose up -d
  log "Stack is starting. Use 'docker compose ps' to see status."
}

main() {
  require_root
  install_prereqs
  setup_docker_repo
  install_docker
  enable_service
  post_install
  add_user_to_group
  bring_up_stack
  log "Done. If running Docker as non-root, re-login to apply docker group membership."
}

main "$@"


