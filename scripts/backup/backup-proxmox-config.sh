#!/bin/bash
set -euo pipefail

#########################################
# Proxmox Host Backup
#
# Version: 2.4
#
# Backs up:
#   - Proxmox host configuration
#   - LXC configuration snapshots
#   - System inventory
#   - SHA256 checksums
#
#########################################

VERSION="2.4"
RETENTION_DAYS=90

START=$(date +%s)

BASE="/srv/backups"

PROXMOX_DIR="$BASE/proxmox"
ARCHIVE_DIR="$PROXMOX_DIR/archives"
INVENTORY_DIR="$PROXMOX_DIR/inventories"
LOG_DIR="$PROXMOX_DIR/logs"
LATEST_DIR="$PROXMOX_DIR/latest"

LXC_DIR="$BASE/lxc/configs"

mkdir -p \
    "$ARCHIVE_DIR" \
    "$INVENTORY_DIR" \
    "$LOG_DIR" \
    "$LATEST_DIR" \
    "$LXC_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/backup-common.sh"

LOGFILE="$LOG_DIR/proxmox-backup.log"
export LOGFILE

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVE="$ARCHIVE_DIR/proxmox-config-$DATE.tar.gz"
CHECKSUM="$ARCHIVE.sha256"

INV="$INVENTORY_DIR/$DATE"
LXC_SNAPSHOT="$LXC_DIR/$DATE"

setup_error_handler

backup_header "Proxmox configuration"

#########################################
# Create configuration archive
#########################################

tar \
    --exclude="$BASE" \
    -czf "$ARCHIVE" \
    /etc/pve \
    /etc/network/interfaces \
    /etc/hosts \
    /etc/fstab \
    /etc/hostname \
    /etc/apt \
    /etc/systemd \
    /etc/default \
    /root

log "Created archive: $(basename "$ARCHIVE")"

#########################################
# Generate SHA256 checksum
#########################################

calculate_checksum  "$ARCHIVE"

log "Generated SHA256 checksum"

#########################################
# Export LXC configurations
#########################################

cp -f /etc/pve/lxc/*.conf "$LXC_SNAPSHOT/" 2>/dev/null || true

ln -sfn "$LXC_SNAPSHOT" "$LXC_DIR/latest"

log "Exported LXC configuration snapshot"

#########################################
# Collect system inventory
#########################################

mkdir -p "$INV"

#########################################
# Basic System Information
#########################################

date > "$INV/date.txt"
hostnamectl > "$INV/hostnamectl.txt"
uname -a > "$INV/uname.txt"

#########################################
# Proxmox Information
#########################################

log "PATH=$PATH"
log "pct=$(command -v pct)"
log "whoami=$(whoami)"

pveversion -v > "$INV/pveversion.txt"

if ! OUTPUT=$(pct list 2>&1); then
    log "pct list failed:"
    log "$OUTPUT"
    exit 1
fi

printf "%s\n" "$OUTPUT" > "$INV/pct-list.txt"

qm list > "$INV/qm-list.txt"

#########################################
# Storage
#########################################

lsblk -f > "$INV/lsblk.txt"
blkid > "$INV/blkid.txt"
mount > "$INV/mount.txt"
df -h > "$INV/df.txt"

cp /etc/pve/storage.cfg "$INV/storage.cfg"
cp /etc/fstab "$INV/fstab"

#########################################
# Network
#########################################

ip addr > "$INV/ip-addr.txt"
ip route > "$INV/ip-route.txt"

cp /etc/network/interfaces "$INV/interfaces"

#########################################
# Hardware
#########################################

lscpu > "$INV/lscpu.txt"
lspci > "$INV/lspci.txt"
lsusb > "$INV/lsusb.txt"

#########################################
# Installed Software
#########################################

apt-mark showmanual > "$INV/manual-packages.txt"
dpkg --get-selections > "$INV/packages.txt"

#########################################
# Services
#########################################

systemctl list-units --type=service --all \
    > "$INV/services.txt"

systemctl list-timers --all \
    > "$INV/systemd-timers.txt"

#########################################
# Scheduled Tasks
#########################################

crontab -l > "$INV/root-crontab.txt"

#########################################
# Journal
#########################################

journalctl --disk-usage \
    > "$INV/journal-size.txt"

#########################################
# Inventory README
#########################################

cat > "$INV/README.txt" <<EOF
==================================================
Proxmox Host Inventory
==================================================

Backup Created : $(date)
Hostname       : $(hostname)
Kernel         : $(uname -r)
PVE Version    : $(pveversion | head -n1)
Script Version : $VERSION
Retention      : $RETENTION_DAYS days

This directory contains a snapshot of the
Proxmox host configuration at backup time.

==================================================
EOF

log "Collected system inventory"

#########################################
# Update latest symlinks
#########################################

create_latest_symlink "$ARCHIVE" "$LATEST_DIR/proxmox-config-latest.tar.gz"
create_latest_symlink "$CHECKSUM" "$LATEST_DIR/proxmox-config-latest.tar.gz.sha256"
create_latest_symlink "$INV" "$LATEST_DIR/inventory"

log "Updated latest symlinks"

#########################################
# Cleanup
#########################################

rotate_backups "$ARCHIVE_DIR" "*.tar.gz"
rotate_backups "$ARCHIVE_DIR" "*.sha256"
rotate_inventory "$INVENTORY_DIR"
rotate_inventory "$LXC_DIR"

log "Cleanup complete"

#########################################
# Summary
#########################################

ARCHIVE_SIZE=$(du -h "$ARCHIVE" | cut -f1)

END=$(date +%s)
ELAPSED=$((END - START))

log "Archive size: $ARCHIVE_SIZE"
log "Completed in ${ELAPSED}s"

#########################################
# Footer
#########################################

backup_footer
