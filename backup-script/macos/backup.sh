#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# --- Load Configuration ---

# Define the path to the configuration file
CONFIG_FILE="./backup.conf" # Adjust this path as needed

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2 # Output error to stderr
    exit 1
fi

# Source (load) the configuration file
source "$CONFIG_FILE"

# --- End Configuration Loading ---


# Derived Configuration Variables (calculated after loading the config)
DATETIME=$(date "+%Y-%m-%d_%H-%M")                      # Timestamp for backup
LATEST_LINK="$BACKUP_ROOT/latest"                       # Symlink to latest backup
BACKUP_LOG_FILE="$BACKUP_ROOT/${DATETIME}_backup.log" # Unique log file for this backup run


# --- Script Logic ---

# Create backup root if it doesn't exist
mkdir -p "$BACKUP_ROOT"

# Create new backup directory
BACKUP_DIR="$BACKUP_ROOT/$DATETIME"
mkdir -p "$BACKUP_DIR"

# Add a separator line to the new log file
echo "============================================================" > "$BACKUP_LOG_FILE"
echo "[$(date)] Starting new backup session" >> "$BACKUP_LOG_FILE"
echo "============================================================" >> "$BACKUP_LOG_FILE"

# Log the start of the backup
echo "[$(date)] Starting backup to $BACKUP_DIR" >> "$BACKUP_LOG_FILE"

# Perform the backup (using the array method)
# We need to convert the space-separated strings from the config file
# into shell arrays.

# Convert SOURCE_DIRS string to an array
read -r -a SOURCE_DIRS_ARRAY <<< "$SOURCE_DIRS"

# Convert EXCLUDE_PATTERNS string to an array
read -r -a EXCLUDE_PATTERNS_ARRAY <<< "$EXCLUDE_PATTERNS"


for src in "${SOURCE_DIRS_ARRAY[@]}"; do
    # Extract only the basename of the source directory (e.g., "files-to-be-backup")
    TARGET_DIR=$(basename "$src")

    # Build the rsync command as an array
    RSYNC_CMD_ARRAY=(rsync -av --delete)

    # Add exclusions from the exclude patterns array
    for pattern in "${EXCLUDE_PATTERNS_ARRAY[@]}"; do
        RSYNC_CMD_ARRAY+=(--exclude="$pattern")
    done

    if [ -d "$LATEST_LINK" ]; then
        RSYNC_CMD_ARRAY+=(--link-dest="$LATEST_LINK/$TARGET_DIR")
    fi

    RSYNC_CMD_ARRAY+=("$src/")
    RSYNC_CMD_ARRAY+=("$BACKUP_DIR/$TARGET_DIR/")

    # Run rsync using the command array and capture its output to the unique log file
    echo "[$(date)] Backing up $src to $BACKUP_DIR/$TARGET_DIR" >> "$BACKUP_LOG_FILE"
    if ! "${RSYNC_CMD_ARRAY[@]}" >> "$BACKUP_LOG_FILE" 2>&1; then
        echo "[$(date)] Error: rsync failed for $src" >> "$BACKUP_LOG_FILE"
        exit 1
    fi
done

# Update the "latest" symlink
rm -f "$LATEST_LINK"
ln -s "$BACKUP_DIR" "$LATEST_LINK"

# Retention policy: delete backups older than RETENTION_DAYS
echo "[$(date)] Cleaning up backups older than $RETENTION_DAYS days" >> "$BACKUP_LOG_FILE"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 \
    \( -type d -o -name "*_backup.log" \) \
    -mtime +$RETENTION_DAYS \
    -exec rm -rf {} \; \
    -exec echo "[$(date)] Deleted old item: {}" >> "$BACKUP_LOG_FILE" \;

# Log the completion of the backup
echo "[$(date)] Backup completed successfully to $BACKUP_DIR" >> "$BACKUP_LOG_FILE"
