#########################################
# Immich
#########################################

IMMICH_ENABLED=true
IMMICH_DISABLED_REASON=""

sync_immich() {
    local DEST="$REPO_DIR/configs/immich"

    echo "Syncing Immich config..."

    #########################################
    # Disabled
    #########################################

    if [[ "$IMMICH_ENABLED" != "true" ]]; then
        echo "Immich export disabled; skipping."

        mkdir -p "$DEST"

        cat > "$DEST/README.md" <<EOF
# Immich Configuration

## Status

Immich configuration export is currently **disabled**.

**Reason:** $IMMICH_DISABLED_REASON

No live Immich configuration is synchronized to this directory.

To re-enable the export, set:

\`\`\`
IMMICH_ENABLED=true
\`\`\`

in:

\`\`\`
scripts/services/immich.sh
\`\`\`

EOF

        record_status "immich" "DISABLED"
        return 0
    fi

    #########################################
    # Dry Run
    #########################################

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would copy Immich configuration"
        record_status "immich" "DRY"
        return 0
    fi

    #########################################
    # Container Check
    #########################################

    if ! is_lxc_running 131; then
        echo "ERROR: Immich container CT131 is not running."
        record_status "immich" "FAILED"
        return 1
    fi

    #########################################
    # Prepare Destination
    #########################################

    if ! mkdir -p "$DEST"; then
        echo "ERROR: Failed to create Immich export directory."
        record_status "immich" "FAILED"
        return 1
    fi

    #########################################
    # Capture Directory Layout
    #########################################

    if ! pct exec 131 -- ls -lah /opt/immich \
        > "$DEST/layout.txt"; then

        echo "ERROR: Failed to capture Immich directory layout."
        record_status "immich" "FAILED"
        return 1
    fi

    #########################################
    # Copy Docker Compose Configuration
    #########################################

    if ! copy_pct_file \
        131 \
        /opt/immich/docker-compose.yml \
        "$DEST/docker-compose.yml"; then

        echo "ERROR: Failed to export Immich docker-compose.yml."
        record_status "immich" "FAILED"
        return 1
    fi

    #########################################
    # Create Sanitized Environment Template
    #########################################

    cat > "$DEST/.env.example" <<EOF
# You can find documentation for all the supported env variables at:
# https://docs.immich.app/install/environment-variables

# Location where uploaded files are stored
UPLOAD_LOCATION=/photos

# Database storage location
DB_DATA_LOCATION=./postgres

# Optional timezone
# TZ=America/New_York

# Immich version
IMMICH_VERSION=v3

# PostgreSQL connection password
# Use only A-Za-z0-9 characters
DB_PASSWORD=CHANGE_ME

# Database configuration
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
EOF

    #########################################
    # Generate README
    #########################################

    cat > "$DEST/README.md" <<EOF
# Immich Configuration

## Overview

Immich provides self-hosted photo and video management for the
homelab.

This directory contains the infrastructure configuration required to
recreate the Immich deployment. Application data is backed up
separately and is not stored in Git.

## Deployment

Immich runs as a Docker Compose deployment in Proxmox LXC CT131.

Live stack directory:

\`\`\`
/opt/immich
\`\`\`

## Tracked Configuration

The following configuration is exported to Git:

- \`docker-compose.yml\`
- \`.env.example\`
- \`layout.txt\`

The exported files document the deployment configuration while
omitting sensitive values and application data.

## Storage

Immich application data is stored outside the Git repository.

Uploaded photos and videos:

\`\`\`
/photos
\`\`\`

PostgreSQL database:

\`\`\`
/opt/immich/postgres
\`\`\`

These locations contain application data and database state and are
backed up separately.

## Secrets

The live Immich deployment uses a \`.env\` file containing environment
variables required by the stack, including the PostgreSQL password.

The live \`.env\` file is intentionally excluded from Git.

A sanitized template is provided as:

\`\`\`
.env.example
\`\`\`

Sensitive values must be supplied separately when recreating the
deployment.

Secrets should never be committed to Git.

## Runtime Data

The following data is intentionally excluded from Git:

- Uploaded photos and videos
- PostgreSQL database
- Application runtime data
- Other instance-specific state

The Git repository contains deployment configuration, not a backup of
the Immich application data.

## Backup

The Immich LXC and application data are protected separately by the
homelab backup strategy.

The exported deployment configuration is also tracked in the homelab
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

    record_status "immich" "OK"
    echo "Immich configuration exported successfully."

    return 0
}
