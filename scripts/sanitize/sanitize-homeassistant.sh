#!/bin/bash
set -euo pipefail

#########################################
#
# Home Assistant Public Sanitizer
#
# Removes private Home Assistant data
# while preserving selected directory
# structure for documentation.
#
#########################################

VERSION="1.0"

PUBLIC_DIR="$1"

log() {
    echo "[$(date '+%F %T')] $*"
}

if [[ -z "$PUBLIC_DIR" ]]; then
    echo "Usage: $0 <public-repository-directory>" >&2
    exit 1
fi

HA_DIR="$PUBLIC_DIR/configs/homeassistant"

if [[ ! -d "$HA_DIR" ]]; then
    log "Home Assistant configuration directory not found. Skipping."
    exit 0
fi

log "Sanitizing Home Assistant configuration..."

#########################################
# Remove private directories entirely
#########################################

PRIVATE_DIRECTORIES=(
    "$HA_DIR/custom_components"
    "$HA_DIR/.storage"
)

for DIRECTORY in "${PRIVATE_DIRECTORIES[@]}"; do

    if [[ ! -d "$DIRECTORY" ]]; then
        continue
    fi

    log "Removing: ${DIRECTORY#$PUBLIC_DIR/}"

    rm -rf "$DIRECTORY"

done

#########################################
# Replace selected directories with
# content-specific README files
#########################################

declare -A DIRECTORY_READMES=(
    ["blueprints"]="$HA_DIR/blueprints/README.md"
    ["www"]="$HA_DIR/www/README.md"
)

for NAME in "${!DIRECTORY_READMES[@]}"; do

    DIRECTORY="$HA_DIR/$NAME"
    README="${DIRECTORY_READMES[$NAME]}"

    log "Sanitizing: ${DIRECTORY#$PUBLIC_DIR/}"

    mkdir -p "$DIRECTORY"

    find "$DIRECTORY" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

    case "$NAME" in

        blueprints)
            cat > "$README" <<'EOF'
# Home Assistant Blueprints

Home Assistant automation blueprints used by the private
homelab are omitted from the public repository.

The directory is preserved to document the expected Home
Assistant configuration structure.
EOF
            ;;

        www)
            cat > "$README" <<'EOF'
# Home Assistant Web Assets

Private Home Assistant frontend assets are omitted from the
public repository.

The directory is preserved to document the expected Home
Assistant configuration structure.
EOF
            ;;

    esac

done

#########################################
# Remove private/generated files
#########################################

PRIVATE_FILES=(
    "$HA_DIR/secrets.yaml"
    "$HA_DIR/home-assistant.log"
    "$HA_DIR/home-assistant_v2.db"
    "$HA_DIR/home-assistant_v2.db-shm"
    "$HA_DIR/home-assistant_v2.db-wal"
)

for FILE in "${PRIVATE_FILES[@]}"; do

    if [[ -e "$FILE" ]]; then
        log "Removing: ${FILE#$PUBLIC_DIR/}"
        rm -rf "$FILE"
    fi

done

log "Home Assistant sanitization complete."
