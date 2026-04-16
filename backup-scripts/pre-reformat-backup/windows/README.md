# Pre-reformat Backup (Windows)

One-time Windows script that backs up your `Documents`, `Desktop`, `Pictures`, and `Downloads` folders to an external drive before you reformat the machine.
Implementation spec: `../docs/windows/pre-reformat-backup/IMPLEMENTATION.md`
Task list: `../docs/windows/pre-reformat-backup/TASKS.md`

## Requirements

- Windows 10 or 11 (also works in Safe Mode with Command Prompt)
- An external drive (USB, SSD, HDD) with enough free space
- No third-party tools — uses only `cmd`, `robocopy`, and `powershell` (built-in)

## Setup

1. Plug in your external drive.
2. Create an empty file named **`.backup-target`** at the **root** of the drive.
   - Example: `E:\.backup-target`
   - In Explorer: enable "File name extensions", create a new text file, rename it to `.backup-target` (remove the `.txt`), and confirm the prompt.
   - In cmd: `type nul > E:\.backup-target`
3. Copy `pre-reformat-backup.bat` anywhere on your machine (e.g. Desktop).

## Run

1. Double-click `pre-reformat-backup.bat` (or run it from a Command Prompt).
2. Follow the on-screen steps:
   1. Read the intro banner, press any key
   2. Confirm the detected drive
   3. Review the per-folder and total size summary
   4. Review the dry-run preview
   5. Type `backup now` exactly to proceed (anything else cancels)
   6. Wait for `robocopy` to finish
   7. Review the log

## Output

- Files are copied to `<DRIVE>:\Backup_YYYY-MM-DD\{Documents,Desktop,Pictures,Downloads}`
- Full log is written to `<DRIVE>:\backup_log_YYYY-MM-DD.txt`

## Configuration

Edit the top of `pre-reformat-backup.bat`:

```
:: === CONFIGURATION ===
set "MARKER_FILE=.backup-target"
:: === END CONFIGURATION ===
```

Change `MARKER_FILE` if you want a different marker filename on the drive.

## Exit codes

- `0` — success or user cancelled
- `1` — no drive with marker file was found
- `>= 8` — robocopy fatal error (drive full, access denied, etc.). Check the log.

## Notes

- Junction points are excluded (`/XJ`) to avoid AppData loops.
- Locked files are retried once, then logged and skipped.
- If multiple drives have the marker file, the first one found (alphabetically D→Z) is used and a warning is shown.
