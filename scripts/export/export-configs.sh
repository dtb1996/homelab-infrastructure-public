#!/bin/bash
set -euo pipefail

#########################################
# Homelab Configs Exporter
#
# Version: 2.0
#########################################

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="/srv/homelab-git"

DRY_RUN="${DRY_RUN:-false}"
AUTO_COMMIT="${AUTO_COMMIT:-false}"
GIT_BRANCH="${GIT_BRANCH:-main}"
GIT_REMOTE="${GIT_REMOTE:-backup}"
GIT_USER_NAME="${GIT_USER_NAME:-Backup}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-123456789+backup@users.noreply.github.com}"

#########################################
# Logging
#########################################

LOG_DIR="/srv/backups/logs"
LOG_FILE="$LOG_DIR/export-configs.log"

mkdir -p "$LOG_DIR"

# Skip log redirection during dry runs
if [[ "$DRY_RUN" != "true" ]]; then
    exec >"$LOG_FILE" 2>&1
fi

echo "========================================"
echo "Configuration Export Started"
echo "Started: $(date)"
echo "Host: $(hostname)"
echo "========================================"
echo

#########################################
# Libraries
#########################################

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"

trap finish EXIT

#########################################
# Dependency Checks
#########################################

if ! check_dependencies; then
    exit 1
fi

#########################################
# Prepare Export Directory
#########################################

CONFIGS_DIR="$REPO_DIR/configs"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would clear configuration export directory:"
    echo "$CONFIGS_DIR"
else
    echo "Clearing configuration export directory..."
    echo "Export directory: $CONFIGS_DIR"

    mkdir -p "$CONFIGS_DIR"

    find "$CONFIGS_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

#########################################
# Service Exporters
#########################################

source "$SCRIPT_DIR/services/proxmox.sh"
source "$SCRIPT_DIR/services/caddy.sh"
source "$SCRIPT_DIR/services/homepage.sh"
source "$SCRIPT_DIR/services/paperless.sh"
source "$SCRIPT_DIR/services/immich.sh"
source "$SCRIPT_DIR/services/docker.sh"
source "$SCRIPT_DIR/services/portainer.sh"
source "$SCRIPT_DIR/services/samba.sh"
source "$SCRIPT_DIR/services/adguard.sh"
source "$SCRIPT_DIR/services/homeassistant.sh"
source "$SCRIPT_DIR/services/jellyfin.sh"
source "$SCRIPT_DIR/services/plex.sh"
source "$SCRIPT_DIR/services/syncthing.sh"

#########################################
# Run Exports
#########################################

sync_proxmox
sync_caddy
sync_homepage
sync_paperless
sync_immich
sync_docker
sync_portainer
sync_samba
sync_adguard
sync_homeassistant
sync_jellyfin
sync_plex
sync_syncthing

#########################################
# Git Commit
#########################################

git_commit_changes

#########################################
# Summary
#########################################

echo
echo "================================="
echo "Config Sync Summary"
echo "================================="

for result in "${SYNC_RESULTS[@]}"; do
    echo "$result"
done

cd "$REPO_DIR"

if [[ "$DRY_RUN" != "true" ]]; then
    git status --short
fi
