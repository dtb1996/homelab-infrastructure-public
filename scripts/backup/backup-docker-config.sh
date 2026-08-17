#!/bin/bash
set -euo pipefail

#########################################
# Docker Configuration Backup
#
# Version: 1.1
#
# Backs up:
#   - Docker Compose stacks
#   - Portainer data
#   - Docker inventories
#
# Retention:
#   - 90 days
#########################################

VERSION="1.1"
RETENTION_DAYS=90

BASE="/srv/backups/docker"

ARCHIVE_DIR="$BASE/archives"
INV_DIR="$BASE/inventories"
LOG_DIR="$BASE/logs"
LATEST_DIR="$BASE/latest"

CTID=100
STACK_DIR="/opt/stacks"
PORTAINER_VOLUME="/var/lib/docker/volumes/portainer_data"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVE="$ARCHIVE_DIR/docker-config-$DATE.tar.gz"
LOGFILE="$LOG_DIR/docker-config-backup.log"
export LOGFILE

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
Docker Configuration Backup

Directory Layout
----------------
archives/
    Compressed Docker configuration backups.

inventories/
    Docker environment snapshots including:
        - Containers
        - Images
        - Networks
        - Volumes
        - Compose projects

latest/
    Symlinks to the newest archive and inventory.

logs/
    Backup logs.

Retention
---------
Archives and inventories older than ${RETENTION_DAYS} days
are automatically removed.

Version
-------
${VERSION}
EOF

#########################################
# Start
#########################################

backup_header "Docker configuration"

if ! pct status "$CTID" >/dev/null 2>&1; then
    log "ERROR: Docker container $CTID does not exist."
    exit 1
fi

if ! pct status "$CTID" | grep -q running; then
    log "ERROR: Docker container $CTID is not running."
    exit 1
fi

if pct exec "$CTID" -- test -d "$STACK_DIR"; then
    log "Verified Docker stack directory."
else
    log "ERROR: Docker stack directory missing: $STACK_DIR"
    exit 1
fi

#########################################
# Create archive
#########################################

log "Creating Docker configuration archive..."

pct exec "$CTID" -- bash -c "
tar -czf /tmp/docker-config.tar.gz \
    $STACK_DIR \
    $PORTAINER_VOLUME
"

pct pull "$CTID" /tmp/docker-config.tar.gz "$ARCHIVE"

pct exec "$CTID" -- rm -f /tmp/docker-config.tar.gz

log "Created archive: $(basename "$ARCHIVE")"

#########################################
# Inventory
#########################################

INV="$INV_DIR/$DATE"
mkdir -p "$INV/containers"
mkdir -p "$INV/compose"
mkdir -p "$INV/docker"

log "Collecting Docker inventory..."

pct exec "$CTID" -- bash -c "docker version" \
    > "$INV/docker-version.txt"

pct exec "$CTID" -- bash -c "docker info" \
    > "$INV/docker-info.txt"

pct exec "$CTID" -- bash -c "docker ps -a" \
    > "$INV/docker-ps.txt"

pct exec "$CTID" -- bash -c "docker images" \
    > "$INV/docker-images.txt"

pct exec "$CTID" -- bash -c "docker network ls" \
    > "$INV/docker-networks.txt"

pct exec "$CTID" -- bash -c "docker volume ls" \
    > "$INV/docker-volumes.txt"

pct exec "$CTID" -- bash -c "docker system df" \
    > "$INV/docker-system-df.txt"

pct exec "$CTID" -- bash -c "docker compose ls" \
    > "$INV/docker-compose-ls.txt" 2>/dev/null || true

pct exec "$CTID" -- bash -c "find $STACK_DIR -name 'docker-compose.yml' -o -name 'compose.yml'" \
    > "$INV/compose-files.txt"

pct exec "$CTID" -- bash -c "cat /etc/docker/daemon.json 2>/dev/null || true" \
    > "$INV/docker/daemon.json"

#########################################
# Container inspection
#########################################

log "Inspecting containers..."

CONTAINERS=$(pct exec "$CTID" -- bash -c "docker ps -a --format '{{.Names}}'")

for CONTAINER in $CONTAINERS
do
    log "Inspecting container: $CONTAINER"

    pct exec "$CTID" -- \
        docker inspect "$CONTAINER" \
        > "$INV/containers/${CONTAINER}.inspect.json" || true

    pct exec "$CTID" -- \
        docker logs --tail 100 "$CONTAINER" \
        > "$INV/containers/${CONTAINER}.log" 2>&1 || true
done

#########################################
# Checksums
#########################################

calculate_checksum "$ARCHIVE"

#########################################
# Latest symlinks
#########################################

create_latest_symlink "$ARCHIVE" "$LATEST_DIR/docker-config-latest.tar.gz"
create_latest_symlink "$INV" "$LATEST_DIR/inventory"

#########################################
# Cleanup
#########################################

rotate_backups "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups "$ARCHIVE_DIR" "*.sha256"
rotate_inventory "$INV_DIR"

#########################################
# Finish
#########################################

log "Docker configuration archive complete"
log "Inventory collected"
log "Latest symlinks updated"
log "Cleanup complete"

#########################################
# Footer
#########################################

backup_footer
