# Backup Script

This script creates incremental backups using `rsync` and manages retention of old backups.

## Configuration

- Set the `SOURCE_DIRS` variable to specify the directories you want to back up.
- To back up multiple directories, you can simply add them to the `SOURCE_DIRS` array in your script.

  ```bash
  SOURCE_DIRS=(
      "/path/to/files-to-be-backup"
      "/path/to/another-directory"
      "/path/to/yet-another-directory"
  )
  ```

- Set the `BACKUP_ROOT` variable to specify the directory where backups will be stored.

- Set the `RETENTION_DAYS` variable to specify how many days of backups you want to keep. Backups older than this period will be automatically deleted the next time the script runs.

## Warning

- Be careful when setting the `BACKUP_ROOT` variable. If misconfigured, the script could delete important files.
- Review the script and customize it for your needs before using it.

## Usage

1. Make the script executable:

   ```bash
   chmod +x backup.sh
   ```

2. Run the script:

   ```bash
   ./backup.sh
   ```

## Disclaimer

This script is provided as is, without warranty of any kind. Use it at your own risk. Review and customize the script before using it.
