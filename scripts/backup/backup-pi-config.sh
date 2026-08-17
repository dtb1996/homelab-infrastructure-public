#!/bin/bash
set -euo pipefail

#########################################
# Raspberry Pi Configuration Backup
#
# Version: 2.3
#
# Managed by the Homelab Git repository.
#
# Source:
#   Proxmox -> homelab-git/scripts/backup/
#
# Deploy with:
#   deploy-pi-backup.sh
#
# Local changes may be overwritten.
#########################################

VERSION="2.3"
RETENTION_DAYS=14

START=$(date +%s)

BASE="$HOME/backups/raspberrypi"

ARCHIVE_DIR="$BASE/archives"
INVENTORY_DIR="$BASE/inventories"
LATEST_DIR="$BASE/latest"
LOG_DIR="$BASE/logs"
DOCKER_VOLUME_DIR="$BASE/docker-volumes"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVE="$ARCHIVE_DIR/raspberrypi-config-$DATE.tar.gz"

mkdir -p \
    "$ARCHIVE_DIR" \
    "$INVENTORY_DIR" \
    "$LATEST_DIR" \
    "$LOG_DIR" \
    "$DOCKER_VOLUME_DIR"

source /usr/local/lib/homelab-backup/backup-common.sh

LOGFILE="$LOG_DIR/raspberrypi-backup.log"
export LOGFILE

setup_error_handler

backup_header "Raspberry Pi Configuration"

#########################################
# Diagnostics
#########################################

log "Hostname: $(hostname)"
log "Running as: $(whoami)"
log "PWD: $(pwd)"
log "PATH: $PATH"

log "Date: $(date)"

log "tar: $(command -v tar || echo missing)"
log "sha256sum: $(command -v sha256sum || echo missing)"
log "docker: $(command -v docker || echo missing)"

if command -v docker >/dev/null 2>&1; then

    if docker info >/dev/null 2>&1; then
        log "Docker daemon: available"
    else
        log "WARNING: Docker installed but daemon unavailable."
    fi

fi

log "Running as PID $$"
id | tee -a "$LOGFILE"

#########################################
# Create Configuration Archive
#########################################

log "Creating configuration archive..."

set +e

tar \
    --exclude="$BASE" \
    -czf "$ARCHIVE" \
    /etc \
    /opt \
    /usr/local \
    /home \
    /root

TAR_EXIT=$?

set -e

case "$TAR_EXIT" in
    0)
        log "Archive created successfully."
        ;;
    1)
        log "Archive completed with warnings (files changed during backup)."
        log "WARNING: Live files changed during backup. This is expected."
        ;;
    *)
        log "ERROR: tar failed (exit code $TAR_EXIT)"
        exit "$TAR_EXIT"
        ;;
esac

#########################################
# Generate Checksum
#########################################

calculate_checksum "$ARCHIVE"

log "Generated SHA256 checksum"

#########################################
# Validate Configuration Archive
#########################################

if [[ ! -s "$ARCHIVE" ]]; then
    log "ERROR: Archive was not created."
    exit 1
fi

ARCHIVE_SIZE=$(du -h "$ARCHIVE" | cut -f1)

log "Archive: $(basename "$ARCHIVE")"
log "Archive size: $ARCHIVE_SIZE"

#########################################
# Docker Volume Backup
#########################################

if command -v docker >/dev/null 2>&1; then

    log "Backing up Docker volumes..."

    VOLUMES=$(docker volume ls -q)

    if [ -n "$VOLUMES" ]; then

        while read -r VOLUME; do

            [ -z "$VOLUME" ] && continue

            log "Backing up Docker volume: $VOLUME"

            docker run --rm \
                -v "$VOLUME:/volume:ro" \
                -v "$DOCKER_VOLUME_DIR:/backup"
                alpine \
                tar czf "/backup/docker-volume-$VOLUME-$DATE.tar.gz" \
                -C /volume .
            
            VOLUME_ARCHIVE="$ARCHIVE_DIR/docker-volume-$VOLUME-$DATE.tar.gz"

            if [[ ! -s "$VOLUME_ARCHIVE" ]]; then
                log "ERROR: Failed to create Docker volume backup: $VOLUME"
                exit 1
            fi

            calculate_checksum "$VOLUME_ARCHIVE"

            log "Created Docker volume backup: $VOLUME ($(du -h "$VOLUME_ARCHIVE" | cut -f1))"

        done <<< "$VOLUMES"

    else
        log "No Docker volumes found"
    fi

else
    log "Docker not installed, skipping volume backup"
fi

#########################################
# Collect Inventory
#########################################

INV="$INVENTORY_DIR/$DATE"

mkdir -p "$INV"

log "Collecting inventory..."

hostnamectl > "$INV/hostnamectl.txt" 2>/dev/null || true
uname -a > "$INV/uname.txt"

cat /etc/os-release > "$INV/os-release.txt"

lsblk -f > "$INV/lsblk.txt"
blkid > "$INV/blkid.txt"

mount > "$INV/mount.txt"
df -h > "$INV/df.txt"

free -h > "$INV/memory.txt"

ip addr > "$INV/ip-addr.txt"
ip route > "$INV/ip-route.txt"

systemctl list-unit-files > "$INV/systemd-unit-files.txt"
systemctl list-units > "$INV/systemd-running.txt"
systemctl list-timers --all > "$INV/systemd-timers.txt"

crontab -l > "$INV/crontab.txt" 2>/dev/null || true

apt-mark showmanual > "$INV/manual-packages.txt"

dpkg --get-selections > "$INV/packages.txt"

#########################################
# Docker Inventory
#########################################

if command -v docker >/dev/null 2>&1; then

    docker ps -a > "$INV/docker-containers.txt"

    docker image ls > "$INV/docker-images.txt"

    docker volume ls > "$INV/docker-volumes.txt"

    docker network ls > "$INV/docker-networks.txt"

    docker inspect $(docker ps -aq) \
        > "$INV/docker-inspect.json" 2>/dev/null || true


    if docker ps --format '{{.Names}}' | grep -q "^uptime-kuma$"; then

        docker inspect uptime-kuma \
            > "$INV/uptime-kuma-inspect.json"

    fi

    find /opt /home /root \
        \( -name docker-compose.yml -o -name compose.yml \) \
        2>/dev/null \
        > "$INV/docker-compose-files.txt" || true
    
    while read -r COMPOSE_FILE; do

        [ -z "$COMPOSE_FILE" ] && continue

        OUTPUT_NAME=$(echo "$COMPOSE_FILE" | tr '/' '_')

        docker compose \
            -f "$COMPOSE_FILE" \
            config \
            > "$INV/${OUTPUT_NAME}.rendered.yml" \
            2>/dev/null || true

    done < "$INV/docker-compose-files.txt"

fi

#########################################
# Service Inventory
#########################################

tailscale status \
    > "$INV/tailscale-status.txt" 2>/dev/null || true


if command -v vcgencmd >/dev/null 2>&1; then

    vcgencmd get_throttled \
        > "$INV/throttled.txt"

    vcgencmd measure_temp \
        > "$INV/cpu-temp.txt"

    vcgencmd measure_volts \
        > "$INV/voltage.txt"

fi

#########################################
# AdGuard Home Inventory
#########################################

if [ -x "/opt/AdGuardHome/AdGuardHome" ]; then

    /opt/AdGuardHome/AdGuardHome --version \
        > "$INV/adguard-version.txt" 2>&1

fi

#########################################
# Important System Files
#########################################

cp /etc/fstab "$INV/" || true
cp /etc/hosts "$INV/" || true
cp /etc/hostname "$INV/" || true

#########################################
# Inventory README
#########################################

cat > "$INV/README.txt" <<EOF
Raspberry Pi Inventory

Generated:
$(date)

Hostname:
$(hostname)

Script Version:
$VERSION

Retention:
$RETENTION_DAYS days

Purpose:
Configuration snapshot used for disaster recovery.

Included:

- Operating system information
- Installed packages
- Network configuration
- Storage information
- Running services
- Cron jobs
- Docker containers
- Docker images
- Docker volumes
- Docker networks
- Docker compose locations
- Container configuration
- Tailscale status
- Raspberry Pi hardware information
- AdGuard Home version

EOF

log "Inventory complete"

#########################################
# Update latest symlinks
#########################################

create_latest_symlink "$ARCHIVE" "$LATEST_DIR/raspberrypi-config-latest.tar.gz"
create_latest_symlink "$ARCHIVE.sha256" "$LATEST_DIR/raspberrypi-config-latest.tar.gz.sha256"
create_latest_symlink "$INV" "$LATEST_DIR/inventory"

log "Updated latest links"

#########################################
# Cleanup
#########################################

log "Cleaning old backups..."

rotate_backups  "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups  "$ARCHIVE_DIR" "*.sha256"
rotate_inventory "$INVENTORY_DIR"

log "Cleanup complete"

#########################################
# Summary
#########################################

END=$(date +%s)
ELAPSED=$((END - START))

log "Completed in ${ELAPSED}s"

#########################################
# Footer
#########################################

backup_footer
