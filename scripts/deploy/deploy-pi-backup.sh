#!/bin/bash
set -euo pipefail

#########################################
#
# Raspberry Pi Backup Deployment
#
# Version: 1.0
#
# Deploys:
# - backup-pi-config.sh
# - backup-common.sh
#
# Installs:
# - /usr/local/bin/backup-pi-config.sh
# - /usr/local/lib/homelab/backup-common.sh
#
#########################################

VERSION="1.0"

SCRIPT_DIR="/srv/homelab-git/scripts"

LOCAL_SCRIPT="$SCRIPT_DIR/backup/backup-pi-config.sh"
LOCAL_LIB="$SCRIPT_DIR/backup/lib/backup-common.sh"

PI_USER="root"
PI_HOST="192.0.2.50"

REMOTE_BIN="/usr/local/bin"
REMOTE_LIB="/usr/local/lib/homelab"

REMOTE_SCRIPT="$REMOTE_BIN/backup-pi-config.sh"
REMOTE_LIBRARY="$REMOTE_LIB/backup-common.sh"

CRON_ENTRY="30 1 * * * /usr/local/bin/backup-pi-config.sh"

#########################################

log() {
    echo "[$(date '+%F %T')] $*"
}

die() {
    log "ERROR: $*"
    exit 1
}

#########################################
# Start
#########################################

log "=========================================="
log "Deploy Raspberry Pi Backup"
log "Version: $VERSION"

#########################################
# Validate local files
#########################################

[[ -f "$LOCAL_SCRIPT" ]] || die "Missing $LOCAL_SCRIPT"
[[ -f "$LOCAL_LIB" ]] || die "Missing $LOCAL_LIB"

#########################################
# Test connectivity
#########################################

log "Testing SSH connectivity..."

ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "$PI_USER@$PI_HOST" \
    "echo connected" >/dev/null \
    || die "Unable to connect to Raspberry Pi."

#########################################
# Create directories
#########################################

log "Creating installation directories..."

ssh "$PI_USER@$PI_HOST" "
mkdir -p \
    '$REMOTE_BIN' \
    '$REMOTE_LIB' \
    /root/backups/raspberrypi/{archives,inventories,latest,logs}
"

#########################################
# Copy files
#########################################

log "Deploying backup-common.sh..."

scp \
    "$LOCAL_LIB" \
    "$PI_USER@$PI_HOST:$REMOTE_LIBRARY"

log "Deploying backup-pi-config.sh..."

scp \
    "$LOCAL_SCRIPT" \
    "$PI_USER@$PI_HOST:$REMOTE_SCRIPT"

#########################################
# Permissions
#########################################

log "Setting permissions..."

ssh "$PI_USER@$PI_HOST" "
chmod 755 '$REMOTE_SCRIPT'
chmod 644 '$REMOTE_LIBRARY'
"

#########################################
# Validate script
#########################################

log "Validating installation..."

ssh "$PI_USER@$PI_HOST" "
bash -n '$REMOTE_SCRIPT'
"

#########################################
# Install cron job
#########################################

log "Ensuring cron job exists..."

ssh "$PI_USER@$PI_HOST" "
(crontab -l 2>/dev/null | grep -F \"$CRON_ENTRY\") \
|| (
    (crontab -l 2>/dev/null; echo \"$CRON_ENTRY\") | crontab -
)
"

#########################################
# Show installed version
#########################################

log "Installed script version:"

ssh "$PI_USER@$PI_HOST" "
grep '^VERSION=' '$REMOTE_SCRIPT'
"

#########################################
# Finish
#########################################

log "Deployment completed successfully."
log "=========================================="
