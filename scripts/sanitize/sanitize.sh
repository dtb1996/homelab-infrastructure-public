#!/bin/bash
set -euo pipefail

#########################################
#
# Homelab Public Repository Sanitizer
#
# Version: 1.2
#
# Copies the private homelab repository
# to a separate public repository directory
# and sanitizes known private information.
#
# IMPORTANT:
# - This script does NOT modify the private repository.
# - The destination Git repository is preserved.
# - Sanitization is intentionally conservative.
# - Review the resulting diff before committing.
#
#########################################

VERSION="1.2"

#########################################
# Configuration
#########################################

SOURCE_DIR="/srv/homelab-git"
PUBLIC_DIR="/srv/homelab-git-public"
SCRIPT_DIR="${SOURCE_DIR}/scripts/sanitize"

#########################################
# Private -> Public replacements
#
# Add entries as:
#
#   ["private value"]="public value"
#
#########################################

declare -A IP_REPLACEMENTS=(
    ["192.0.2.1"]="192.0.2.1"
    ["192.0.2.50"]="192.0.2.50"
    ["192.0.2.10"]="192.0.2.10"
    ["192.0.2.20"]="192.0.2.20"
    ["192.0.2.21"]="192.0.2.21"
    ["192.0.2.22"]="192.0.2.22"
    ["192.0.2.30"]="192.0.2.30"
    ["192.0.2.40"]="192.0.2.40"
    ["192.0.2.41"]="192.0.2.41"
    ["192.0.2.23"]="192.0.2.23"
    ["192.0.2.42"]="192.0.2.42"
    ["192.0.2.91"]="192.0.2.91"
    ["192.0.2.92"]="192.0.2.92"
    ["192.0.2.0"]="192.0.2.0"
)

declare -A EMAIL_REPLACEMENTS=(
    ["user@example.com"]="user@example.com"
    ["backup@example.com"]="backup@example.com"
)

declare -A GIT_REPO_REPLACEMENTS=(
    ["git@github.com:example/homelab-infrastructure.git"]="git@github.com:example/homelab-infrastructure.git"
    ["123456789+backup@users.noreply.github.com"]="123456789+backup@users.noreply.github.com"
    ["Backup"]="Backup"
)

declare -A DOMAIN_REPLACEMENTS=(
    ["example.com"]="example.com"
)

declare -A HOSTNAME_REPLACEMENTS=(
    # ["proxmox"]="proxmox-host"
    # ["docker"]="docker-host"
)

declare -A STORAGE_PATH_REPLACEMENTS=(
    ["/srv"]="/srv"
    ["/mnt/backup"]="/mnt/backup"
)

#########################################
# Files requiring sanitized replacements
#########################################

SANITIZED_FILES=(
    "configs/jellyfin/libraries.txt"
    "configs/plex/libraries.txt"
)

#########################################
# Private-only files/directories
#
# These are removed from the public copy.
#########################################

PRIVATE_PATHS=(
    ".gitignore.private"
    ".env"
    ".env.local"
)

#########################################
# Functions
#########################################

log() {
    echo "[$(date '+%F %T')] $*"
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

#########################################
# Validate source
#########################################

if [[ ! -d "$SOURCE_DIR" ]]; then
    error "Source repository does not exist: $SOURCE_DIR"
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    error "Source directory does not appear to be a Git repository: $SOURCE_DIR"
fi

#########################################
# Validate destination
#########################################

if [[ -e "$PUBLIC_DIR" && ! -d "$PUBLIC_DIR" ]]; then
    error "Public path exists but is not a directory: $PUBLIC_DIR"
fi

if [[ -d "$PUBLIC_DIR/.git" ]]; then
    log "Existing public Git repository detected."
    log "Its .git directory will be preserved."
else
    log "No existing public Git repository detected."
    log "A Git repository can be initialized manually after sanitization."
fi

#########################################
# Confirm paths
#########################################

if [[ "$SOURCE_DIR" == "$PUBLIC_DIR" ]]; then
    error "Source and destination cannot be the same directory."
fi

log "=========================================="
log "Homelab Public Repository Sanitizer"
log "Version: $VERSION"
log "=========================================="

log "Source:      $SOURCE_DIR"
log "Destination: $PUBLIC_DIR"

#########################################
# Create destination
#########################################

mkdir -p "$PUBLIC_DIR"

#########################################
# Copy repository contents
#
# IMPORTANT:
# The destination .git directory is excluded
# so the public repository history/remotes
# are never overwritten.
#########################################

log "Copying repository contents..."

rsync -a \
    --delete \
    --exclude='.git/' \
    "$SOURCE_DIR/" \
    "$PUBLIC_DIR/"

#########################################
# Remove private-only paths
#########################################

log "Removing private-only files..."

for PATH_TO_REMOVE in "${PRIVATE_PATHS[@]}"; do

    TARGET="$PUBLIC_DIR/$PATH_TO_REMOVE"

    if [[ -e "$TARGET" ]]; then
        log "Removing: $PATH_TO_REMOVE"
        rm -rf "$TARGET"
    fi

done

#########################################
# Add Public Repository Notice
#########################################

log "Adding public repository notice..."

PUBLIC_README="$PUBLIC_DIR/README.md"

if [[ -f "$PUBLIC_README" ]]; then

    if ! grep -qF '> **Note**' "$PUBLIC_README"; then

        TEMP_README="$(mktemp)"

        awk '
        /^## / && !inserted {
            print "> **Note**"
            print ">"
            print "> This repository is a sanitized version of my production homelab."
            print "> Sensitive information such as domains, IP addresses, credentials,"
            print "> and personal identifiers have been replaced with example values."
            print ""
            inserted = 1
        }
        { print }
        END {
            if (!inserted) {
                print ""
                print "> **Note**"
                print ">"
                print "> This repository is a sanitized version of my production homelab."
                print "> Sensitive information such as domains, IP addresses, credentials,"
                print "> and personal identifiers have been replaced with example values."
            }
        }
        ' "$PUBLIC_README" > "$TEMP_README"

        mv "$TEMP_README" "$PUBLIC_README"

        log "Added public repository notice."

    else
        log "Public repository notice already present."
    fi

else
    log "WARNING: Public README not found; skipping public repository notice."
fi

#########################################
# Replacement functions
#########################################

replace_ips() {

    log "Sanitizing IP addresses..."

    for PRIVATE_IP in "${!IP_REPLACEMENTS[@]}"; do

        PUBLIC_IP="${IP_REPLACEMENTS[$PRIVATE_IP]}"

        log "  $PRIVATE_IP -> $PUBLIC_IP"

        while IFS= read -r -d '' FILE; do

            sed -i -E \
                "s/(^|[^0-9])${PRIVATE_IP//./\\.}([^0-9]|$)/\1${PUBLIC_IP}\2/g" \
                "$FILE"

        done < <(
            grep -RIlZ \
                --exclude-dir=.git \
                -- "$PRIVATE_IP" \
                "$PUBLIC_DIR" \
                2>/dev/null || true
        )

    done
}

replace_values() {

    local CATEGORY="$1"
    declare -n REPLACEMENTS="$2"

    log "Sanitizing $CATEGORY..."

    for PRIVATE_VALUE in "${!REPLACEMENTS[@]}"; do

        PUBLIC_VALUE="${REPLACEMENTS[$PRIVATE_VALUE]}"

        log "  $PRIVATE_VALUE -> $PUBLIC_VALUE"

        while IFS= read -r -d '' FILE; do

            sed -i "s|$PRIVATE_VALUE|$PUBLIC_VALUE|g" "$FILE"

        done < <(
            grep -RIlZ \
                --exclude-dir=.git \
                -- "$PRIVATE_VALUE" \
                "$PUBLIC_DIR" \
                2>/dev/null || true
        )

    done
}

#########################################
# Sanitized file replacements
#########################################

sanitize_media_libraries() {

    local MEDIA_LIBRARY_CONTENT
    MEDIA_LIBRARY_CONTENT="/media
/media/Movies
/media/Movies/Example Movie (2024)
/media/Movies/Another Movie (2023)
/media/TV
/media/TV/Example Series
/media/TV/Example Series/Season 01
/media/Music
/media/Music/Example Artist
/media/Music/Example Artist/Example Album"

    log "Sanitizing media library inventories..."

    for RELATIVE_FILE in "${SANITIZED_FILES[@]}"; do

        FILE="$PUBLIC_DIR/$RELATIVE_FILE"

        if [[ ! -f "$FILE" ]]; then
            log "  Skipping missing file: $RELATIVE_FILE"
            continue
        fi

        log "  Replacing: $RELATIVE_FILE"

        printf '%s\n' "$MEDIA_LIBRARY_CONTENT" > "$FILE"

    done
}

#########################################
# MAC Address Sanitization
#########################################

sanitize_mac_addresses() {

    log "Sanitizing MAC addresses..."

    local MAC_COUNT=0

    # Find unique MAC addresses in the public repository.
    # Matches:
    #   02:c1:79:95:64:f2
    #   02:c1:79:95:64:f2
    #
    # The regex intentionally requires exactly six hexadecimal
    # octets separated by ':' or '-'.

    mapfile -t MAC_ADDRESSES < <(
        grep -RhoE \
            --exclude-dir=.git \
            '([[:xdigit:]]{2}[:-]){5}[[:xdigit:]]{2}' \
            "$PUBLIC_DIR" 2>/dev/null |
        sort -fu
    )

    for MAC in "${MAC_ADDRESSES[@]}"; do

        # Normalize the MAC before hashing so that different
        # capitalization/separators produce the same replacement.
        NORMALIZED_MAC=$(echo "$MAC" | tr '[:upper:]' '[:lower:]' | tr -d ':-')

        # Generate a deterministic SHA-256 hash.
        HASH=$(printf '%s' "$NORMALIZED_MAC" | sha256sum | cut -c1-10)

        # Locally administered unicast MAC:
        #   02 = locally administered + unicast
        FAKE_MAC="02:${HASH:0:2}:${HASH:2:2}:${HASH:4:2}:${HASH:6:2}:${HASH:8:2}"

        log "  $MAC -> $FAKE_MAC"

        # Escape the original MAC for use as a sed pattern.
        ESCAPED_MAC=$(printf '%s' "$MAC" | sed 's/[][\/.^$*\\]/\\&/g')

        while IFS= read -r -d '' FILE; do

            sed -i "s|$ESCAPED_MAC|$FAKE_MAC|g" "$FILE"

        done < <(
            grep -RIlZ \
                --exclude-dir=.git \
                -- "$MAC" \
                "$PUBLIC_DIR" \
                2>/dev/null || true
        )

        ((MAC_COUNT+=1))

    done

    log "MAC addresses sanitized: $MAC_COUNT"
}

#########################################
# Sanitization Verification
#########################################

verify_sanitization() {

    local FAILED=0

    log "=========================================="
    log "Sanitization Verification"
    log "=========================================="

    #########################################
    # Check replacement values
    #########################################

    check_replacements() {

        local CATEGORY="$1"
        declare -n REPLACEMENTS="$2"
        local CATEGORY_FAILED=0

        for PRIVATE_VALUE in "${!REPLACEMENTS[@]}"; do

            if grep -RIl \
                --exclude-dir=.git \
                -- "$PRIVATE_VALUE" \
                "$PUBLIC_DIR" \
                >/dev/null 2>&1
            then
                log "FAIL: Private $CATEGORY value remains: $PRIVATE_VALUE"
                CATEGORY_FAILED=1
                FAILED=1
            fi

        done

        if [[ "$CATEGORY_FAILED" -eq 0 ]]; then
            log "PASS: $CATEGORY"
        fi
    }

    check_replacements "storage path" STORAGE_PATH_REPLACEMENTS
    check_replacements "email address" EMAIL_REPLACEMENTS
    check_replacements "domain" DOMAIN_REPLACEMENTS
    check_replacements "hostname" HOSTNAME_REPLACEMENTS

    #########################################
    # Check IP addresses
    #########################################

    log "Checking private IP addresses..."

    for PRIVATE_IP in "${!IP_REPLACEMENTS[@]}"; do

        if grep -RIl \
            --exclude-dir=.git \
            -- "$PRIVATE_IP" \
            "$PUBLIC_DIR" \
            >/dev/null 2>&1
        then
            log "FAIL: Private IP address remains: $PRIVATE_IP"
            FAILED=1
        fi

    done

    if [[ "$FAILED" -eq 0 ]]; then
        log "PASS: IP addresses"
    fi

    #########################################
    # Check MAC addresses
    #########################################

    log "Checking for remaining MAC addresses..."

    REMAINING_MACS=$(
        grep -RhoE \
            --exclude-dir=.git \
            '([[:xdigit:]]{2}[:-]){5}[[:xdigit:]]{2}' \
            "$PUBLIC_DIR" 2>/dev/null |
        grep -viE '^02([:-][[:xdigit:]]{2}){5}$' |
        sort -fu || true
    )

    if [[ -n "$REMAINING_MACS" ]]; then

        log "FAIL: Possible unsanitized MAC addresses found:"

        while IFS= read -r MAC; do
            log "  $MAC"
        done <<< "$REMAINING_MACS"

        FAILED=1

    else

        log "PASS: MAC addresses"

    fi

    #########################################
    # Final result
    #########################################

    if [[ "$FAILED" -ne 0 ]]; then

        log "=========================================="
        log "SANITIZATION FAILED"
        log "Review the public repository before committing."
        log "=========================================="

        return 1

    fi

    log "=========================================="
    log "SANITIZATION PASSED"
    log "No configured private values or unsanitized MAC addresses were detected."
    log "=========================================="

    return 0
}

#########################################
# Sanitize known private values
#########################################

replace_ips
replace_values "email addresses" EMAIL_REPLACEMENTS
replace_values "domains" DOMAIN_REPLACEMENTS
replace_values "hostnames" HOSTNAME_REPLACEMENTS
replace_values "storage paths" STORAGE_PATH_REPLACEMENTS
replace_values "Git repository URLs" GIT_REPO_REPLACEMENTS
sanitize_media_libraries
sanitize_mac_addresses

#########################################
# Application-specific sanitization
#########################################

HA_SANITIZER="$SCRIPT_DIR/sanitize-homeassistant.sh"

if [[ ! -x "$HA_SANITIZER" ]]; then
    error "Home Assistant sanitizer not found or not executable: $HA_SANITIZER"
fi

log "Running Home Assistant sanitization..."

"$HA_SANITIZER" "$PUBLIC_DIR"

#########################################
# Verify Sanitization
#########################################

verify_sanitization

#########################################
# Final audit
#########################################

log "=========================================="
log "Sanitization complete"
log "=========================================="

log "Public repository:"
log "$PUBLIC_DIR"

echo
log "IMPORTANT:"
log "Review the public repository before committing."
log "Run:"
log "  cd $PUBLIC_DIR"
log "  git status"
log "  git diff"
echo

#########################################
# Suggested searches
#########################################

log "Suggested final checks:"
echo
echo "  grep -RniE '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' ."
echo "  grep -RniE '\\b([0-9]{1,3}\\.){3}[0-9]{1,3}\\b' ."
echo "  grep -RniE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}' ."
echo
