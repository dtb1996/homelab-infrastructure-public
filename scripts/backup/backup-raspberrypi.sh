#!/bin/bash
set -euo pipefail

#########################################
#
# Raspberry Pi Backup Pull
#
# Version: 1.3
#
# Pulls:
# - Raspberry Pi configuration backups
# - Inventories
# - Checksums
#
#########################################

VERSION="1.2"
RETENTION_DAYS=30

BASE="/srv/backups/raspberrypi"

ARCHIVE_DIR="$BASE/archives"
INVENTORY_DIR="$BASE/inventories"
LATEST_DIR="$BASE/latest"
LOG_DIR="$BASE/logs"

LOGFILE="$LOG_DIR/raspberrypi-backup.log"
export LOGFILE

source /srv/homelab-infrastructure/scripts/backup/lib/backup-common.sh

PI_USER="root"
PI_HOST="192.0.2.50"
SSH_OPTS=(-i /root/.ssh/id_ed25519_raspberrypi_backup -o IdentitiesOnly=yes)

REMOTE_DIR="/root/backups/raspberrypi"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p \
"$ARCHIVE_DIR" \
"$INVENTORY_DIR" \
"$LATEST_DIR" \
"$LOG_DIR"

setup_error_handler

#########################################
# Generate README
#########################################

cat > "$BASE/README.md" <<EOF
Raspberry Pi Backup

## Directory Layout

archives/
Backups pulled from the Raspberry Pi.

inventories/
Raspberry Pi inventory snapshots.

latest/
Symlinks to newest backup.

logs/
Backup logs.

## Retention

Backups older than ${RETENTION_DAYS} days
are removed automatically.

## Version

${VERSION}
EOF

#########################################
# Start
#########################################

backup_header "Raspberry Pi"

#########################################
# Test SSH connection
#########################################

log "Testing SSH connectivity..."

if ! ssh "${SSH_OPTS[@]}" \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "$PI_USER@$PI_HOST" \
    "echo connected" >/dev/null
then
    log "ERROR: Unable to reach Raspberry Pi."
    exit 1
fi

#########################################
# Verify backup exists remotely
#########################################

if ! ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" \
    "test -d '$REMOTE_DIR'"
then
    log "ERROR: Remote backup directory not found."
    exit 1
fi

#########################################
# Log remote storage
#########################################

log "Remote backup usage:"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" \
    "du -sh '$REMOTE_DIR'"

#########################################
# Sync backup data
#########################################

log "Syncing Raspberry Pi backups..."

if ! rsync -aH --delete --stats \
    -e "ssh -i /root/.ssh/id_ed25519_raspberrypi_backup -o IdentitiesOnly=yes" \
    "$PI_USER@$PI_HOST:$REMOTE_DIR/" \
    "$BASE/"
then
    log "ERROR: rsync failed."
    exit 1
fi

#########################################
# Validation
#########################################

if ! find "$ARCHIVE_DIR" -name "*.tar.gz" | grep -q .
then
    log "ERROR: No Raspberry Pi archives were synchronized."
    exit 1
fi

# Log the synchronized archive count
ARCHIVE_COUNT=$(find "$ARCHIVE_DIR" -name "*.tar.gz" | wc -l)

log "Archives available: $ARCHIVE_COUNT"

#########################################
# Inventory
#########################################

INV="$INVENTORY_DIR/$DATE"

mkdir -p "$INV"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" hostname \
    > "$INV/hostname.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" uname -a \
    > "$INV/uname.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" df -h \
    > "$INV/df.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" free -h \
    > "$INV/memory.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" systemctl list-units --type=service \
    > "$INV/services.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" cat /etc/os-release \
    > "$INV/os-release.txt"

ssh "${SSH_OPTS[@]}" "$PI_USER@$PI_HOST" vcgencmd version 2>/dev/null \
    > "$INV/firmware.txt" || true

cat > "$INV/README.txt" <<EOF
Raspberry Pi Backup Inventory

Created:
$(date)

Host:
$PI_HOST

Script Version:
$VERSION
EOF

#########################################
# Cleanup old archives
#########################################

log "Cleaning old archives..."

rotate_backups "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups "$ARCHIVE_DIR" "*.sha256"
rotate_inventory "$INVENTORY_DIR"

#########################################
# Latest Symlinks
#########################################

LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.tar.gz" | sort | tail -1)

if [[ -n "$LATEST_ARCHIVE" ]]; then
    create_latest_symlink \
        "$LATEST_ARCHIVE" \
        "$LATEST_DIR/latest-backup.tar.gz"
fi

create_latest_symlink \
    "$INV" \
    "$LATEST_DIR/inventory"

# Log the newest archive
log "Latest archive: $(basename "$LATEST_ARCHIVE")"

#########################################
# Footer
#########################################

backup_footer
