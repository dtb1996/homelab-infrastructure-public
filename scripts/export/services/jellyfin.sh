#########################################
# Jellyfin
#########################################

JELLYFIN_ENABLED=true
JELLYFIN_DISABLED_REASON=""

sync_jellyfin() {
    local DEST="$REPO_DIR/configs/jellyfin"

    echo "Syncing Jellyfin config..."

    #########################################
    # Disabled
    #########################################

    if [[ "$JELLYFIN_ENABLED" != "true" ]]; then
        echo "Jellyfin export disabled; skipping."

        mkdir -p "$DEST"

        cat > "$DEST/README.md" <<EOF
# Jellyfin Configuration

## Status

Jellyfin configuration export is currently **disabled**.

**Reason:** $JELLYFIN_DISABLED_REASON

No live Jellyfin configuration is synchronized to this directory.

To re-enable the export, set:

\`\`\`
JELLYFIN_ENABLED=true
\`\`\`

in:

\`\`\`
scripts/services/jellyfin.sh
\`\`\`

EOF

        record_status "jellyfin" "DISABLED"
        return 0
    fi

    #########################################
    # Dry Run
    #########################################

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would copy Jellyfin configuration"
        record_status "jellyfin" "DRY"
        return 0
    fi

    #########################################
    # Container Check
    #########################################

    if ! is_lxc_running 101; then
        echo "ERROR: Jellyfin container CT101 is not running."
        record_status "jellyfin" "FAILED"
        return 1
    fi

    #########################################
    # Prepare Destination
    #########################################

    if ! mkdir -p "$DEST/config"; then
        echo "ERROR: Failed to create Jellyfin export directory."
        record_status "jellyfin" "FAILED"
        return 1
    fi

    #########################################
    # Jellyfin Environment Configuration
    #########################################

    if ! pct exec 101 -- cat /etc/default/jellyfin \
        > "$DEST/default-jellyfin"; then

        echo "ERROR: Failed to export Jellyfin environment configuration."
        record_status "jellyfin" "FAILED"
        return 1
    fi

    #########################################
    # Systemd Override Configuration
    #########################################

    if pct exec 101 -- \
        test -f /etc/systemd/system/jellyfin.service.d/jellyfin.service.conf; then

        if ! pct exec 101 -- \
            cat /etc/systemd/system/jellyfin.service.d/jellyfin.service.conf \
            > "$DEST/service-override.conf"; then

            echo "ERROR: Failed to export Jellyfin systemd override."
            record_status "jellyfin" "FAILED"
            return 1
        fi
    fi

    #########################################
    # Export Jellyfin Configuration
    #########################################

    if ! pct exec 101 -- tar \
        --exclude='./data' \
        --exclude='./cache' \
        --exclude='./logs' \
        --exclude='./transcodes' \
        -C /etc/jellyfin \
        -cf - \
        . \
    | tar -C "$DEST/config" -xf -; then

        echo "ERROR: Failed to export Jellyfin configuration."
        record_status "jellyfin" "FAILED"
        return 1
    fi

    #########################################
    # Remove Runtime Files
    #########################################

    rm -rf \
        "$DEST/config/data" \
        "$DEST/config/cache" \
        "$DEST/config/logs"

    #########################################
    # Capture Media Library Structure
    #########################################

    if ! pct exec 101 -- bash -c \
        'find /media -maxdepth 2 -type d | sort' \
        > "$DEST/libraries.txt"; then

        echo "ERROR: Failed to export Jellyfin library paths."
        record_status "jellyfin" "FAILED"
        return 1
    fi

    #########################################
    # Generate README
    #########################################

    cat > "$DEST/README.md" <<EOF
# Jellyfin Configuration

## Overview

Jellyfin provides self-hosted media streaming for the homelab.

## Deployment

Jellyfin is installed directly on Proxmox LXC CT101 as a native
systemd service.

System configuration:

\`\`\`
/etc/jellyfin
\`\`\`

Runtime data:

\`\`\`
/var/lib/jellyfin
\`\`\`

## Tracked Configuration

The following configuration is exported to Git:

- \`default-jellyfin\`
- \`service-override.conf\` (if present)
- \`config/\`
- \`libraries.txt\`

The exported configuration provides a sanitized representation of the
Jellyfin installation without including runtime application data.

## Runtime Data

Jellyfin runtime data is intentionally excluded from Git.

This includes:

- Database
- Metadata
- Cache
- Transcoding files
- Logs

Runtime data is protected separately by the homelab backup strategy.

## Media Libraries

Media files are stored separately from the Jellyfin configuration.

Configured library locations include:

\`\`\`
/media/Movies
/media/TV
/media/Music
\`\`\`

The actual media files are not stored in Git.

The exported \`libraries.txt\` file documents the configured library
structure using a sanitized representation of the media paths.

## Backup

The Jellyfin LXC is protected by the normal Proxmox backup process.

Media storage is protected separately by the homelab storage and backup
strategy.

The exported Jellyfin configuration is also tracked in the homelab
Git repository.

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

    record_status "jellyfin" "OK"
    echo "Jellyfin configuration exported successfully."

    return 0
}
