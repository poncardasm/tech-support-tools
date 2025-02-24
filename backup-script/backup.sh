#!/bin/bash

# Configuration
SOURCE_DIRS=("/path/to/files-to-be-backup")             # Directories to backup
BACKUP_ROOT="/path/to/backup-location"                  # Where backups will be stored
DATETIME=$(date "+%Y-%m-%d_%H-%M")                      # Timestamp for backup
LATEST_LINK="$BACKUP_ROOT/latest"                       # Symlink to latest backup
LOG_FILE="$BACKUP_ROOT/backup.log"                      # Log file for backup operations
RETENTION_DAYS=3                                        # Number of days to keep old backups
EXCLUDE_PATTERNS=(".DS_Store" "*.tmp")                  # Patterns to exclude from backup

# Create backup root if it doesn't exist
mkdir -p "$BACKUP_ROOT"

# Create new backup directory
BACKUP_DIR="$BACKUP_ROOT/$DATETIME"
mkdir -p "$BACKUP_DIR"

# Add a separator line to the log file
echo "============================================================" >> "$LOG_FILE"
echo "[$(date)] Starting new backup session" >> "$LOG_FILE"
echo "============================================================" >> "$LOG_FILE"

# Log the start of the backup
echo "[$(date)] Starting backup to $BACKUP_DIR" >> "$LOG_FILE"

# Perform the backup
for src in "${SOURCE_DIRS[@]}"; do
    # Extract only the basename of the source directory (e.g., "files-to-be-backup")
    TARGET_DIR=$(basename "$src")

    # Build the rsync command
    RSYNC_CMD="rsync -av --delete"
    
    # Add exclusions to the rsync command
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        RSYNC_CMD+=" --exclude=$pattern"
    done

    # If we have a previous backup, use it as a reference
    if [ -d "$LATEST_LINK" ]; then
        RSYNC_CMD+=" --link-dest=$LATEST_LINK/$TARGET_DIR"
    fi

    # Run rsync and capture its output
    echo "[$(date)] Backing up $src to $BACKUP_DIR/$TARGET_DIR" >> "$LOG_FILE"
    if ! eval "$RSYNC_CMD \"$src/\" \"$BACKUP_DIR/$TARGET_DIR/\"" >> "$LOG_FILE" 2>&1; then
        echo "[$(date)] Error: rsync failed for $src" >> "$LOG_FILE"
        exit 1
    fi
done

# Update the "latest" symlink
rm -f "$LATEST_LINK"
ln -s "$BACKUP_DIR" "$LATEST_LINK"

# Retention policy: delete backups older than RETENTION_DAYS
echo "[$(date)] Cleaning up backups older than $RETENTION_DAYS days" >> "$LOG_FILE"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; \
    -exec echo "[$(date)] Deleted old backup: {}" >> "$LOG_FILE" \;

# Log the completion of the backup
echo "[$(date)] Backup completed successfully to $BACKUP_DIR" >> "$LOG_FILE"
