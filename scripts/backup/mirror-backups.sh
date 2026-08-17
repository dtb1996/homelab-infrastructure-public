#!/bin/bash
set -euo pipefail

#########################################
# Backup Mirror
#
# Version: 2.2
#
# Mirrors the primary backup repository
# from the HDD to the USB backup drive.
#########################################

VERSION="2.2"

START=$(date +%s)

SITE="homelab"
HOSTNAME=$(hostname -s)

SOURCE="/srv/backups/"
DEST="/mnt/backup/backups/$SITE/$HOSTNAME"

LOGFILE="/srv/backups/logs/mirror-backups.log"

mkdir -p "$DEST"
mkdir -p "$(dirname "$LOGFILE")"

log() {
    echo "[$(date '+%F %T')] $1" | tee -a "$LOGFILE"
}

trap 'log "ERROR: Mirror failed on line $LINENO"; exit 1' ERR

log "=================================================="
log "Starting backup mirror"
log "Version: $VERSION"
log "Source: $SOURCE"
log "Destination: $DEST"

rsync \
    -aHAX \
    --delete \
    --stats \
    "$SOURCE" \
    "$DEST" | tee -a "$LOGFILE"

END=$(date +%s)
ELAPSED=$((END - START))

log "Mirror completed in ${ELAPSED}s"
