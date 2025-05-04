#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Configuration
SOURCE_DIRS=("/path/to/files-to-be-backup")             # Directories to backup
BACKUP_ROOT="/path/to/backup-location"                  # Where backups will be stored
DATETIME=$(date "+%Y-%m-%d_%H-%M")                      # Timestamp for backup
LATEST_LINK="$BACKUP_ROOT/latest"                       # Symlink to latest backup
# Define the log file path using the timestamp
BACKUP_LOG_FILE="$BACKUP_ROOT/${DATETIME}_backup.log" # Unique log file for this backup run
RETENTION_DAYS=3                                        # Number of days to keep old backups
EXCLUDE_PATTERNS=(".DS_Store" "*.tmp")                  # Patterns to exclude from backup

# Create backup root if it doesn't exist
mkdir -p "$BACKUP_ROOT"

# Create new backup directory
BACKUP_DIR="$BACKUP_ROOT/$DATETIME"
mkdir -p "$BACKUP_DIR"

# Add a separator line to the new log file
# Use > for the first write to create/overwrite the file
echo "============================================================" > "$BACKUP_LOG_FILE"
echo "[$(date)] Starting new backup session" >> "$BACKUP_LOG_FILE"
echo "============================================================" >> "$BACKUP_LOG_FILE"

# Log the start of the backup
echo "[$(date)] Starting backup to $BACKUP_DIR" >> "$BACKUP_LOG_FILE"

# Perform the backup (using the array method)
for src in "${SOURCE_DIRS[@]}"; do
    # Extract only the basename of the source directory (e.g., "files-to-be-backup")
    TARGET_DIR=$(basename "$src")

    # Build the rsync command as an array
    RSYNC_CMD_ARRAY=(rsync -av --delete)

    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
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
        # You might want to log a *separate* critical error message
        # to a *different* file or system log here as well,
        # so you don't miss rsync failures if you only check the individual backup logs.
        exit 1
    fi
done

# Update the "latest" symlink
rm -f "$LATEST_LINK"
ln -s "$BACKUP_DIR" "$LATEST_LINK"

# Retention policy: delete backups older than RETENTION_DAYS
echo "[$(date)] Cleaning up backups older than $RETENTION_DAYS days" >> "$BACKUP_LOG_FILE"
# You'll also want to clean up the old log files that correspond to deleted backups.
# We can modify the find command to find directories and log files.
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 \
    \( -type d -o -name "*_backup.log" \) \
    -mtime +$RETENTION_DAYS \
    -exec rm -rf {} \; \
    -exec echo "[$(date)] Deleted old item: {}" >> "$BACKUP_LOG_FILE" \;

# Log the completion of the backup
echo "[$(date)] Backup completed successfully to $BACKUP_DIR" >> "$BACKUP_LOG_FILE"
