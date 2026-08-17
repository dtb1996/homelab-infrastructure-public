#!/bin/bash
set -euo pipefail

#########################################
#
# Home Assistant Backup
#
# Version: 1.2
#
# Backs up:
# - Home Assistant configuration
# - Automations/scripts/scenes
# - Custom components
# - Frontend assets
# - SQLite database
# - Docker Compose stack
# - Container inventory
#
#########################################

VERSION="1.2"
RETENTION_DAYS=30

BASE="/srv/backups/homeassistant"

ARCHIVE_DIR="$BASE/archives"
INV_DIR="$BASE/inventories"
LOG_DIR="$BASE/logs"
LATEST_DIR="$BASE/latest"

LOGFILE="$LOG_DIR/homeassistant-backup.log"
export LOGFILE

CTID=140

COMPOSE_DIR="/opt/homeassistant"
CONFIG_DIR="$COMPOSE_DIR/config"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVE="$ARCHIVE_DIR/homeassistant-$DATE.tar.gz"

mkdir -p \
"$ARCHIVE_DIR" \
"$INV_DIR" \
"$LOG_DIR" \
"$LATEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/backup-common.sh"

setup_error_handler

#########################################
# Generate README
#########################################

cat > "$BASE/README.md" <<EOF
Home Assistant Backup

## Directory Layout

archives/
Compressed Home Assistant configuration backups.

inventories/
System and container snapshots.

latest/
Symlinks to newest backup.

logs/
Backup logs.

## Retention

Archives older than ${RETENTION_DAYS} days
are removed automatically.

## Version

${VERSION}
EOF

#########################################
# Start
#########################################

backup_header "Home Assistant"

#########################################
# Verify LXC
#########################################

if ! pct status "$CTID" >/dev/null 2>&1; then
    log "ERROR: Home Assistant container $CTID does not exist."
    exit 1
fi

STATUS=$(pct status "$CTID" | awk '{print $2}')

if [[ "$STATUS" != "running" ]]; then
    log "ERROR: Home Assistant container $CTID is not running."
    exit 1
fi

#########################################
# Verify files
#########################################

if ! pct exec "$CTID" -- test -f "$COMPOSE_DIR/docker-compose.yml"; then
    log "ERROR: Missing docker-compose.yml"
    exit 1
fi

if ! pct exec "$CTID" -- test -d "$CONFIG_DIR"; then
    log "ERROR: Missing Home Assistant config directory"
    exit 1
fi

#########################################
# Inventory
#########################################

INV="$INV_DIR/$DATE"

mkdir -p "$INV"

log "Collecting Home Assistant inventory..."

pct exec "$CTID" -- bash -c \
"docker ps -a" \
> "$INV/docker-ps.txt" 2>&1 || true

pct exec "$CTID" -- bash -c \
"docker inspect homeassistant" \
> "$INV/homeassistant.inspect.json" 2>&1 || true

pct exec "$CTID" -- bash -c \
"docker logs --tail 100 homeassistant" \
> "$INV/homeassistant.log" 2>&1 || true

pct exec "$CTID" -- bash -c \
"docker compose -f $COMPOSE_DIR/docker-compose.yml config" \
> "$INV/docker-compose-rendered.yml" 2>&1 || true

pct exec "$CTID" -- bash -c \
"cat $COMPOSE_DIR/docker-compose.yml" \
> "$INV/docker-compose.yml" 2>&1 || true

pct exec "$CTID" -- bash -c \
"du -sh $CONFIG_DIR" \
> "$INV/config-size.txt" 2>&1 || true

pct exec "$CTID" -- bash -c \
"du -sh $CONFIG_DIR/home-assistant_v2.db 2>/dev/null || true" \
> "$INV/database-size.txt"

pct exec "$CTID" -- bash -c \
"docker exec homeassistant python -m homeassistant --version" \
> "$INV/homeassistant-version.txt" 2>&1 || true

cat > "$INV/README.txt" <<EOF
Home Assistant Backup Inventory

Created:
$(date)

Container:
$CTID

Compose Directory:
$COMPOSE_DIR

Config Directory:
$CONFIG_DIR

Script Version:
$VERSION

Inventory may contain sensitive information.
Protect backup storage appropriately.
EOF

#########################################
# Stop Home Assistant
#########################################

log "Stopping Home Assistant..."

pct exec "$CTID" -- bash -c \
"cd $COMPOSE_DIR && docker compose stop"

#########################################
# Create archive
#########################################

log "Creating Home Assistant archive..."

pct exec "$CTID" -- \
tar -czf - \
-C /opt \
homeassistant \
> "$ARCHIVE"

#########################################
# Restart Home Assistant
#########################################

log "Starting Home Assistant..."

pct exec "$CTID" -- bash -c \
"cd $COMPOSE_DIR && docker compose start"

#########################################
# Validate archive
#########################################

if [[ ! -s "$ARCHIVE" ]]; then
    log "ERROR: Archive is empty!"
    exit 1
fi

ARCHIVE_SIZE=$(du -h "$ARCHIVE" | cut -f1)

log "Created archive: $(basename "$ARCHIVE")"
log "Archive size: $ARCHIVE_SIZE"

#########################################
# Checksums
#########################################

calculate_checksum "$ARCHIVE"

#########################################
# Latest symlinks
#########################################

create_latest_symlink \
"$ARCHIVE" \
"$LATEST_DIR/homeassistant-latest.tar.gz"

create_latest_symlink \
"$ARCHIVE.sha256" \
"$LATEST_DIR/homeassistant-latest.tar.gz.sha256"

create_latest_symlink \
"$INV" \
"$LATEST_DIR/inventory"

#########################################
# Cleanup
#########################################

rotate_backups "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups "$ARCHIVE_DIR" "*.sha256"

rotate_inventory "$INV_DIR"

#########################################
# Finish
#########################################

log "Home Assistant archive complete"
log "Inventory collected"
log "Checksums generated"
log "Latest symlinks updated"
log "Cleanup complete"

#########################################
# Footer
#########################################

backup_footer
