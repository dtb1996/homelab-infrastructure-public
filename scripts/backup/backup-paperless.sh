#!/bin/bash
set -euo pipefail

#########################################
# Paperless Data Backup
#
# Version: 1.2
#
# Backs up:
# - Paperless application data
# - Document media library
# - Consume/export directories
# - PostgreSQL logical database dump
# - Docker Compose stack
# - Container inventory
#
# Does NOT backup:
# - PostgreSQL raw data directory
#
#########################################

VERSION="1.2"
RETENTION_DAYS=90

BASE="/srv/backups/paperless"

ARCHIVE_DIR="$BASE/archives"
DB_DIR="$BASE/databases"
INV_DIR="$BASE/inventories"
LOG_DIR="$BASE/logs"
LATEST_DIR="$BASE/latest"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVE="$ARCHIVE_DIR/paperless-data-$DATE.tar.gz"
DATABASE="$DB_DIR/paperless-db-$DATE.sql.gz"

LOGFILE="$LOG_DIR/paperless-backup.log"
export LOGFILE

CTID=100

STACK_DIR="/opt/stacks/paperless"

PAPERLESS_DIRS=(
    "/storage/paperless/data"
    "/documents/paperless/media"
    "/documents/paperless/export"
    "/documents/paperless/consume"
)

DB_CONTAINER="paperless-db"
DB_USER="paperless"

APP_CONTAINER="paperless"
REDIS_CONTAINER="paperless-redis"

mkdir -p \
    "$ARCHIVE_DIR" \
    "$DB_DIR" \
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
Paperless Backup

Directory Layout
----------------
archives/
    Compressed archive of the Paperless data directory
    and Docker Compose stack.

databases/
    PostgreSQL logical database dumps (.sql.gz).

inventories/
    Docker inspection files and runtime information.

latest/
    Symlinks to the newest backup.

logs/
    Backup logs.

Retention
---------
Backups older than ${RETENTION_DAYS} days are removed automatically.

Version
-------
${VERSION}
EOF

#########################################
# Start
#########################################

backup_header "Paperless"

if ! pct status "$CTID" >/dev/null 2>&1; then
    log "ERROR: Paperless container $CTID does not exist."
    exit 1
fi

if ! pct status "$CTID" | grep -q running; then
    log "ERROR: Paperless container $CTID is not running."
    exit 1
fi

if ! pct exec "$CTID" -- test -d "$STACK_DIR"; then
    log "ERROR: Missing Paperless stack directory: $STACK_DIR"
    exit 1
fi

for DIR in "${PAPERLESS_DIRS[@]}"; do

    if ! pct exec "$CTID" -- test -d "$DIR"; then
        log "ERROR: Missing Paperless directory: $DIR"
        exit 1
    fi

done

#########################################
# Backup Paperless data
#########################################

log "Paperless storage usage:"
pct exec "$CTID" -- du -sh \
    /storage/paperless/data \
    /documents/paperless/media \
    /documents/paperless/export \
    /documents/paperless/consume

log "Creating Paperless data archive inside container..."

TEMP_ARCHIVE="/tmp/paperless-data-$DATE.tar.gz"

pct exec "$CTID" -- bash -c "
tar --checkpoint=1000 \
    --checkpoint-action=exec='echo Archived \$TAR_CHECKPOINT files' \
    -czf '$TEMP_ARCHIVE' \
    '$STACK_DIR' \
    '${PAPERLESS_DIRS[0]}' \
    '${PAPERLESS_DIRS[1]}' \
    '${PAPERLESS_DIRS[2]}' \
    '${PAPERLESS_DIRS[3]}'
"

log "Copying Paperless archive to Proxmox host..."

pct pull "$CTID" \
    "$TEMP_ARCHIVE" \
    "$ARCHIVE"

pct exec "$CTID" -- rm -f "$TEMP_ARCHIVE"

log "Created archive: $(basename "$ARCHIVE")"

#########################################
# PostgreSQL logical dump
#########################################

log "Creating PostgreSQL database dump inside container..."

TEMP_DATABASE="/tmp/paperless-db-$DATE.sql.gz"

if ! pct exec "$CTID" -- docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER"; then
    log "ERROR: PostgreSQL is not ready"
    exit 1
fi

pct exec "$CTID" -- bash -c "
docker exec $DB_CONTAINER pg_dumpall -U $DB_USER | gzip > $TEMP_DATABASE
"

if ! pct exec "$CTID" -- test -s "$TEMP_DATABASE"; then
    log "ERROR: Database dump was not created"
    exit 1
fi

log "Copying database dump to Proxmox host..."

pct pull "$CTID" \
"$TEMP_DATABASE" \
"$DATABASE"

if [ ! -s "$DATABASE" ]; then
    log "ERROR: Database dump is empty!"
    exit 1
fi

pct exec "$CTID" -- rm -f "$TEMP_DATABASE"

log "Database dump created: $(basename "$DATABASE")"

#########################################
# Inventory
#########################################

INV="$INV_DIR/$DATE"

mkdir -p "$INV"

log "Collecting Paperless inventory..."

pct exec "$CTID" -- docker ps \
    > "$INV/docker-ps.txt"

pct exec "$CTID" -- docker inspect "$APP_CONTAINER" \
    > "$INV/paperless.inspect.json" 2>&1 || true

pct exec "$CTID" -- docker inspect "$DB_CONTAINER" \
    > "$INV/paperless-db.inspect.json" 2>&1 || true

pct exec "$CTID" -- docker inspect "$REDIS_CONTAINER" \
    > "$INV/paperless-redis.inspect.json" 2>&1 || true

pct exec "$CTID" -- docker logs --tail 100 "$APP_CONTAINER" \
    > "$INV/paperless.log" 2>&1 || true

pct exec "$CTID" -- docker logs --tail 100 "$DB_CONTAINER" \
    > "$INV/postgres.log" 2>&1 || true

pct exec "$CTID" -- docker logs --tail 100 "$REDIS_CONTAINER" \
    > "$INV/redis.log" 2>&1 || true

pct exec "$CTID" -- bash -c "docker compose -f $STACK_DIR/docker-compose.yml config" \
    > "$INV/docker-compose-rendered.yml" 2>&1 || true

pct exec "$CTID" -- bash -c "cat $STACK_DIR/.env 2>/dev/null || true" \
    > "$INV/paperless.env"

# Inventory README

cat > "$INV/README.txt" <<EOF
Paperless Backup Inventory

Created:
$(date)

Container:
$CTID

Stack:
$STACK_DIR

Data directories:
$(printf '%s\n' "${PAPERLESS_DIRS[@]}")

Script Version:
$VERSION

Inventory files may contain sensitive credentials.
Protect backup storage appropriately.
EOF

#########################################
# Checksums
#########################################

calculate_checksum "$ARCHIVE"
calculate_checksum "$DATABASE"

#########################################
# Latest symlinks
#########################################

create_latest_symlink "$ARCHIVE" "$LATEST_DIR/paperless-data-latest.tar.gz"
create_latest_symlink "$DATABASE" "$LATEST_DIR/paperless-db-latest.sql.gz"
create_latest_symlink "$INV" "$LATEST_DIR/inventory"

#########################################
# Cleanup
#########################################

rotate_backups "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups "$ARCHIVE_DIR" "*.sha256"
rotate_backups "$DB_DIR" "*.sql.gz"
rotate_backups "$DB_DIR" "*.sha256"
rotate_inventory "$INV_DIR"

#########################################
# Finish
#########################################

log "Paperless archive complete"
log "Database dump complete"
log "Inventory collected"
log "Checksums generated"
log "Latest symlinks updated"
log "Cleanup complete"

#########################################
# Footer
#########################################

backup_footer
