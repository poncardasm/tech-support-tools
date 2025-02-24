# Configuration
$SOURCE_DIRS = @("C:\path\to\files-to-be-backup")      # Directories to backup
$BACKUP_ROOT = "C:\path\to\backup-location"            # Where backups will be stored
$DATETIME = Get-Date -Format "yyyy-MM-dd_HH-mm"        # Timestamp for backup
$LATEST_LINK = Join-Path $BACKUP_ROOT "latest"         # Link to latest backup
$LOG_FILE = Join-Path $BACKUP_ROOT "backup.log"        # Log file for backup operations
$RETENTION_DAYS = 3                                    # Number of days to keep old backups
$EXCLUDE_PATTERNS = @(".DS_Store", "*.tmp")            # Patterns to exclude from backup

# Function to write to log file
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Add-Content -Path $LOG_FILE
}

# Check for administrator privileges
if (-not ([bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "This script must be run as an administrator." -ForegroundColor Red
    exit 1
}

# Create backup root if it doesn't exist
if (-not (Test-Path $BACKUP_ROOT)) {
    New-Item -ItemType Directory -Path $BACKUP_ROOT | Out-Null
}

# Create new backup directory
$BACKUP_DIR = Join-Path $BACKUP_ROOT $DATETIME
New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null

# Add a separator line to the log file
"============================================================" | Add-Content -Path $LOG_FILE
Write-Log "Starting new backup session"
"============================================================" | Add-Content -Path $LOG_FILE

# Log the start of the backup
Write-Log "Starting backup to $BACKUP_DIR"

# Perform the backup
foreach ($src in $SOURCE_DIRS) {
    # Extract only the basename of the source directory
    $TARGET_DIR = Split-Path $src -Leaf
    $DEST_DIR = Join-Path $BACKUP_DIR $TARGET_DIR

    Write-Log "Backing up $src to $DEST_DIR"

    try {
        # Create destination directory
        New-Item -ItemType Directory -Path $DEST_DIR -Force | Out-Null

        # If we have a previous backup, use it as a reference for hard links
        $REFERENCE_DIR = $null
        if (Test-Path $LATEST_LINK) {
            $REFERENCE_DIR = Join-Path $LATEST_LINK $TARGET_DIR
        }

        # Get source items
        $items = Get-ChildItem -Path $src -Recurse | 
            Where-Object {
                $item = $_
                -not ($EXCLUDE_PATTERNS | Where-Object { $item.Name -like $_ })
            }

        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($src.Length + 1)
            $destPath = Join-Path $DEST_DIR $relativePath

            if ($item.PSIsContainer) {
                if (-not (Test-Path $destPath)) {
                    New-Item -ItemType Directory -Path $destPath | Out-Null
                }
            }
            else {
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir | Out-Null
                }

                # If reference directory exists, try to create hard link
                if ($REFERENCE_DIR -and (Test-Path (Join-Path $REFERENCE_DIR $relativePath))) {
                    $refPath = Join-Path $REFERENCE_DIR $relativePath
                    $hardLinkUtil = "$env:SystemRoot\System32\fsutil.exe"
                    & $hardLinkUtil hardlink create "$destPath" "$refPath" | Out-Null
                    if (-not $?) {
                        Copy-Item -Path $item.FullName -Destination $destPath -Force
                    }
                }
                else {
                    Copy-Item -Path $item.FullName -Destination $destPath -Force
                }
            }
        }
    }
    catch {
        Write-Log "Error: Failed to backup $src. Error: $_"
        exit 1
    }
}

# Update the "latest" link
if (Test-Path $LATEST_LINK) {
    Remove-Item $LATEST_LINK -Force
}

# Create a directory junction (closest thing to a symlink in Windows)
$null = & cmd /c mklink /J "$LATEST_LINK" "$BACKUP_DIR"

# Retention policy: delete backups older than RETENTION_DAYS
Write-Log "Cleaning up backups older than $RETENTION_DAYS days"
Get-ChildItem -Path $BACKUP_ROOT -Directory | 
    Where-Object { 
        $_.Name -ne "latest" -and 
        $_.LastWriteTime -lt (Get-Date).AddDays(-$RETENTION_DAYS) 
    } | 
    ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
        Write-Log "Deleted old backup: $($_.FullName)"
    }

# Log the completion of the backup
Write-Log "Backup completed successfully to $BACKUP_DIR"