# Windows Pre-reformat Backup — Implementation Plan

## Overview

One-time pre-reformat backup script for Windows. Detects external drive via marker file, scans standard user folders, displays size summary, requires explicit typed confirmation, then performs mirror backup with logging.

---

## Step 1: Intro Banner

Display this text:

```md
====================================
WINDOWS USER DATA BACKUP v1.0
by Mchael Poncardas (poncardas.com)
====================================

This script will:
1. Detect your external backup drive
2. Scan your Documents, Desktop, Pictures, and Downloads folders
3. Show total files and size to be backed up
4. Preview what will be copied
5. Ask for explicit confirmation before starting
6. Copy files using robocopy with logging

Press any key to continue...
```

Wait for keypress before proceeding.

---

## Step 2: External Drive Detection

- Loop through drive letters D: to Z:
- Check for marker file named `.backup-target` at root of each drive
- First drive with this file wins — store as `%BACKUP_DRIVE%`
- If no drive found, display error and exit with code 1
- If multiple drives have the marker, use first one found and display warning

---

## Step 3: Source Folder Definition

Set these 4 source paths using `%USERPROFILE%`:
- `%USERPROFILE%\Documents`
- `%USERPROFILE%\Desktop`
- `%USERPROFILE%\Pictures`
- `%USERPROFILE%\Downloads`

---

## Step 4: Size Calculation

For each of the 4 folders:
- Use `dir /s` to get file count and size
- Parse the summary line (contains "File(s)" and size in bytes)
- Accumulate total files and total bytes across all folders

Display:

```md
BACKUP SUMMARY
--------------
Documents:   X files, Y GB
Desktop:     X files, Y GB
Pictures:    X files, Y GB
Downloads:   X files, Y GB
--------------
TOTAL:       X files, Y GB
DESTINATION: %BACKUP_DRIVE%\
```

---

## Step 5: Dry-Run Preview

Run robocopy with `/L` flag on all 4 folders to destination subfolders:
- `%BACKUP_DRIVE%\Backup_YYYY-MM-DD\Documents`
- Same pattern for Desktop, Pictures, Downloads

Display:

```md
DRY-RUN PREVIEW (no files copied yet)
robocopy would copy: [show summary counts, not full file list]
```

---

## Step 6: Explicit Confirmation

Display prompt:

```md
Type "backup now" exactly to proceed with the backup.
Any other input will cancel.

> 
```

- Read user input
- If input equals `backup now`, proceed to Step 7
- If any other input, display "Backup cancelled." and exit with code 0

---

## Step 7: Execute Backup

Create timestamped folder: `%BACKUP_DRIVE%\Backup_YYYY-MM-DD`

Run robocopy for each folder WITHOUT `/L`:

- Flags: `/E /XJ /R:1 /W:1 /TEE /LOG+:%BACKUP_DRIVE%\backup_log_YYYY-MM-DD.txt`
- `/E` = include subdirectories (empty ones too)
- `/XJ` = exclude junction points (prevents AppData loops)
- `/R:1` = retry once on locked files
- `/W:1` = wait 1 second between retries
- `/TEE` = show output + write to log
- `/LOG+:` = append to log file

---

## Step 8: Completion

Display:

```md
Backup complete.
Files copied to: %BACKUP_DRIVE%\Backup_YYYY-MM-DD
Log file: %BACKUP_DRIVE%\backup_log_YYYY-MM-DD.txt

Review the log for any skipped files.
Press any key to exit...
```

Wait for keypress, then exit with code 0.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Missing marker file | Clear error message, exit code 1 |
| Source folder doesn't exist | Skip with warning, continue |
| Drive full during copy | Capture robocopy error, display "Backup incomplete — drive may be full" |
| Locked files | Acceptable to skip, robocopy logs this |

---

## User Configuration Section

Editable section at top of script:

```batch
:: === CONFIGURATION ===
:: Marker filename on external drive (create this file at root of your backup drive)
set MARKER_FILE=.backup-target

:: Optional: add custom folders here if needed (one per line)
:: set EXTRA_FOLDER_1=%USERPROFILE%\Music
:: === END CONFIGURATION ===
```

---

## Notes

- Uses only built-in Windows commands (batch + robocopy)
- Safe Mode compatible
- No external dependencies
- Explicit confirmation prevents accidental execution
