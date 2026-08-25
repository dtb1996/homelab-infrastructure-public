#########################################
# Proxmox
#########################################

PROXMOX_ENABLED=true
PROXMOX_DISABLED_REASON=""

sync_proxmox() {
    local DEST="$REPO_DIR/configs/proxmox"

    echo "Syncing Proxmox config..."

    #########################################
    # Disabled
    #########################################

    if [[ "$PROXMOX_ENABLED" != "true" ]]; then
        echo "Proxmox export disabled; skipping."

        mkdir -p "$DEST"

        cat > "$DEST/README.md" <<EOF
# Proxmox Configuration

## Status

Proxmox configuration export is currently **disabled**.

**Reason:** $PROXMOX_DISABLED_REASON

No live Proxmox configuration is synchronized to this directory.

To re-enable the export, set:

\`\`\`
PROXMOX_ENABLED=true
\`\`\`

in:

\`\`\`
scripts/services/proxmox.sh
\`\`\`

EOF

        record_status "proxmox" "DISABLED"
        return 0
    fi

    #########################################
    # Dry Run
    #########################################

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would sync Proxmox configuration"
        record_status "proxmox" "DRY"
        return 0
    fi

    #########################################
    # Prepare Destination
    #########################################

    if ! mkdir -p "$DEST"; then
        echo "ERROR: Failed to create Proxmox export directory."
        record_status "proxmox" "FAILED"
        return 1
    fi

    #########################################
    # Configuration Files
    #########################################

    if ! cp /etc/hosts "$DEST/hosts"; then
        echo "ERROR: Failed to export /etc/hosts."
        record_status "proxmox" "FAILED"
        return 1
    fi

    if ! cp /etc/network/interfaces "$DEST/interfaces"; then
        echo "ERROR: Failed to export network interfaces configuration."
        record_status "proxmox" "FAILED"
        return 1
    fi

    if ! cp /etc/pve/storage.cfg "$DEST/storage.cfg"; then
        echo "ERROR: Failed to export storage.cfg."
        record_status "proxmox" "FAILED"
        return 1
    fi

    if ! cp /etc/pve/datacenter.cfg "$DEST/datacenter.cfg"; then
        echo "ERROR: Failed to export datacenter.cfg."
        record_status "proxmox" "FAILED"
        return 1
    fi

    #########################################
    # Root Crontab
    #########################################

    mkdir -p "$DEST/cron"

    if ! crontab -l > "$DEST/cron/root.crontab"; then
        echo "ERROR: Failed to export root crontab."
        record_status "proxmox" "FAILED"
        return 1
    fi

    #########################################
    # LXC Configurations
    #########################################

    mkdir -p "$DEST/lxc"

    if ! cp /etc/pve/lxc/*.conf "$DEST/lxc/"; then
        echo "ERROR: Failed to export LXC configurations."
        record_status "proxmox" "FAILED"
        return 1
    fi

    #########################################
    # Installed Packages Inventory
    #########################################

    if ! dpkg-query -W -f='${binary:Package}\t${Version}\n' \
        | sort > "$DEST/packages.txt"; then

        echo "ERROR: Failed to export installed package inventory."
        record_status "proxmox" "FAILED"
        return 1
    fi

    #########################################
    # Generate README
    #########################################

    cat > "$DEST/README.md" <<EOF
# Proxmox Configuration

## Overview

Proxmox VE is the virtualization platform hosting the homelab's
virtual machines, LXC containers, storage, and infrastructure
services.

This directory contains a sanitized export of the host configuration
used for documentation, version control, and disaster recovery.

## Deployment

The configuration is exported directly from the Proxmox VE host.

Primary Proxmox configuration is stored under:

\`\`\`
/etc/pve
\`\`\`

Additional host configuration is collected from:

\`\`\`
/etc/hosts
/etc/network/interfaces
\`\`\`

## Tracked Configuration

The following configuration is exported to Git:

- \`hosts\`
- \`interfaces\`
- \`storage.cfg\`
- \`datacenter.cfg\`
- \`cron/root.crontab\`
- \`lxc/\`
- \`packages.txt\`

The \`lxc/\` directory contains the configuration files for the LXC
containers hosted by Proxmox.

The \`packages.txt\` file provides an inventory of installed Debian
packages and their versions.

## Runtime Data

Runtime and application data is intentionally excluded from Git.

This includes:

- Virtual machine disks
- LXC root filesystems
- Application data
- Container runtime state
- Proxmox task history and logs
- Storage contents

These resources are protected separately by the homelab backup and
storage strategy.

## Storage

Proxmox storage configuration is exported from:

\`\`\`
/etc/pve/storage.cfg
\`\`\`

The exported configuration documents the storage definitions used by
the host but does not contain the underlying storage data.

## Network

Host network configuration is exported from:

\`\`\`
/etc/network/interfaces
\`\`\`

The host's network identity and local hostname mappings are also
represented by:

\`\`\`
hosts
\`\`\`

## Backup

Proxmox configuration is tracked in the homelab Git repository.

Virtual machines, LXC containers, and their application data are
protected separately through the Proxmox backup strategy.

The Git repository should be treated as a configuration and
documentation source rather than a replacement for full Proxmox
backups.

## Configuration Management

This documentation is generated by:

\`\`\`
scripts/export-configs.sh
\`\`\`

The README is regenerated during each configuration export.

EOF

    #########################################
    # Success
    #########################################

    record_status "proxmox" "OK"
    echo "Proxmox configuration exported successfully."

    return 0
}
