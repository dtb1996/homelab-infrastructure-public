#########################################
# Syncthing
#########################################

SYNCTHING_ENABLED=true
SYNCTHING_DISABLED_REASON=""

sync_syncthing() {
    local DEST="$REPO_DIR/configs/syncthing"

    echo "Syncing Syncthing config..."

    #########################################
    # Disabled
    #########################################

    if [[ "$SYNCTHING_ENABLED" != "true" ]]; then
        echo "Syncthing export disabled; skipping."

        mkdir -p "$DEST"

        cat > "$DEST/README.md" <<EOF
# Syncthing Configuration

## Status

Syncthing configuration export is currently **disabled**.

**Reason:** $SYNCTHING_DISABLED_REASON

No live Syncthing configuration is synchronized to this directory.

To re-enable the export, set:

\`\`\`
SYNCTHING_ENABLED=true
\`\`\`

in:

\`\`\`
scripts/services/syncthing.sh
\`\`\`

EOF

        record_status "syncthing" "DISABLED"
        return 0
    fi

    #########################################
    # Dry Run
    #########################################

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would export Syncthing configuration summary"
        record_status "syncthing" "DRY"
        return 0
    fi

    #########################################
    # Container Check
    #########################################

    if ! is_lxc_running 121; then
        echo "ERROR: Syncthing container CT121 is not running."
        record_status "syncthing" "FAILED"
        return 1
    fi

    #########################################
    # Prepare Destination
    #########################################

    if ! mkdir -p "$DEST"; then
        echo "ERROR: Failed to create Syncthing export directory."
        record_status "syncthing" "FAILED"
        return 1
    fi

    #########################################
    # Service Information
    #########################################

    if ! pct exec 121 -- systemctl cat syncthing@syncthing.service \
        > "$DEST/service-info.txt"; then

        echo "ERROR: Failed to export Syncthing service information."
        record_status "syncthing" "FAILED"
        return 1
    fi

    #########################################
    # Version
    #########################################

    if ! pct exec 121 -- syncthing --version \
        > "$DEST/version.txt"; then

        echo "ERROR: Failed to export Syncthing version."
        record_status "syncthing" "FAILED"
        return 1
    fi

    #########################################
    # Mount Information
    #########################################

    if ! pct exec 121 -- findmnt /data \
        > "$DEST/mount.txt"; then

        echo "ERROR: Failed to export Syncthing mount information."
        record_status "syncthing" "FAILED"
        return 1
    fi

    #########################################
    # Generate README
    #########################################

    cat > "$DEST/README.md" <<EOF
# Syncthing Configuration

## Overview

Syncthing provides a continuously available synchronization endpoint
for Dusklight save data shared between the Windows RetroBat
installation and Android device.

Syncthing runs as a native systemd service in Proxmox LXC CT121.

## Deployment

| Property       | Value            |
| -------------- | ---------------- |
| Container      | CT121            |
| Hostname       | syncthing        |
| OS             | Debian           |
| Container Type | Unprivileged LXC |
| CPU            | 1 core           |
| Memory         | 512 MiB          |
| Root Disk      | 8 GiB            |
| Data Mount     | \`/data\`        |

Systemd service:

\`\`\`
syncthing@syncthing.service
\`\`\`

The service is enabled and starts automatically with the container.

## Tracked Configuration

The following service information is exported to Git:

- \`service-info.txt\`
- \`version.txt\`
- \`mount.txt\`
- \`README.md\`

The repository intentionally contains a sanitized, human-readable
representation of the service configuration rather than Syncthing's
raw configuration database.

## Runtime Data

Syncthing stores its runtime configuration under:

\`\`\`
/var/lib/syncthing/.local/state/syncthing/
\`\`\`

The following instance-specific data is intentionally excluded from
Git:

- Syncthing configuration XML
- Device IDs
- Device certificates
- Private keys
- HTTPS certificates
- HTTPS private keys
- Runtime locks

This information is protected by the LXC backup instead.

## Storage

Syncthing uses a Proxmox bind mount.

Container:

\`\`\`
/data
\`\`\`

Host:

\`\`\`
/mnt/backup/shared/syncthing
\`\`\`

Dusklight synchronization data:

\`\`\`
/data/dusklight
\`\`\`

The synchronized game data is stored separately from the Git
repository.

## Dusklight Synchronization

The synchronized folder contains the shared Dusklight data required by
the supported clients.

Tracked synchronization data includes:

\`\`\`
achievements.json
USA/Card A/01-GZ2E-gczelda2.gci
\`\`\`

Platform-specific files and directories are excluded using Syncthing
ignore patterns.

Current ignored content includes:

\`\`\`
/texture_replacements/
config.json
imgui.ini
*.dat
*.controller
\`\`\`

The Android-specific \`EUR\` directory and other client-specific
directories may remain locally present but are not intended to be part
of the synchronized save data.

## Network

Syncthing uses its standard synchronization and discovery protocols.

The Web GUI is bound to localhost inside the container and is not
directly exposed to the network.

The synchronization service uses the standard Syncthing service ports.

## Backup

The complete Syncthing LXC is protected by the normal Proxmox backup
process.

This includes:

- Syncthing installation
- Service configuration
- Runtime configuration
- LXC configuration

The synchronized Dusklight data is stored separately on USB storage
and is protected by the homelab storage backup strategy.

## Security

The following information must never be committed to Git:

- Device IDs
- Device certificates
- Private keys
- HTTPS keys
- API credentials
- Authentication credentials
- Raw Syncthing configuration containing private information

Any configuration exported to the repository should be reviewed
before being made public.

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

    record_status "syncthing" "OK"
    echo "Syncthing configuration exported successfully."

    return 0
}
