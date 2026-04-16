# Windows Pre-reformat Backup — Tasks
Task checklist derived from `IMPLEMENTATION.md`. Work top-to-bottom; each task maps to a section in the implementation plan.
## 0. Project Setup
- [ ] Create script file `pre-reformat-backup.bat` in the target scripts directory
- [ ] Add header comment block (title, author, version, purpose)
- [ ] Enable `@echo off` and `setlocal EnableDelayedExpansion` at top of script
- [ ] Add the **User Configuration Section** block (`MARKER_FILE`, commented extra-folder examples)
## 1. Intro Banner
- [ ] Print the `WINDOWS USER DATA BACKUP v1.0` banner exactly as specified
- [ ] Print the 6-step "This script will:" list
- [ ] Print "Press any key to continue..." and wait for keypress via `pause >nul`
## 2. External Drive Detection
- [ ] Loop drive letters `D` through `Z`
- [ ] For each letter, test existence of `%MARKER_FILE%` at the drive root
- [ ] Store the first matching drive letter in `%BACKUP_DRIVE%`
- [ ] If a second matching drive is found, print a warning and keep the first
- [ ] If no drive has the marker, print clear error and `exit /b 1`
## 3. Source Folder Definition
- [ ] Define `SRC_DOCUMENTS=%USERPROFILE%\Documents`
- [ ] Define `SRC_DESKTOP=%USERPROFILE%\Desktop`
- [ ] Define `SRC_PICTURES=%USERPROFILE%\Pictures`
- [ ] Define `SRC_DOWNLOADS=%USERPROFILE%\Downloads`
- [ ] Verify each folder exists; if missing, flag it to be skipped later with a warning
## 4. Size Calculation
- [ ] For each source folder, run `dir /s /-c` and capture output
- [ ] Parse the summary line (contains `File(s)`) to extract file count and byte size
- [ ] Accumulate `TOTAL_FILES` and `TOTAL_BYTES` across all folders
- [ ] Convert bytes to GB for display (integer math or `set /a` with MB intermediate)
- [ ] Render the `BACKUP SUMMARY` block with per-folder and total rows
- [ ] Append `DESTINATION: %BACKUP_DRIVE%\` to the summary
## 5. Dry-Run Preview
- [ ] Compute date stamp `YYYY-MM-DD` (locale-independent, e.g. via `wmic os get localdatetime` or `powershell Get-Date`)
- [ ] Set `DEST_ROOT=%BACKUP_DRIVE%\Backup_YYYY-MM-DD`
- [ ] For each source, run `robocopy <src> <DEST_ROOT>\<name> /E /XJ /L`
- [ ] Suppress full file list; show only summary counts in the `DRY-RUN PREVIEW` block
## 6. Explicit Confirmation
- [ ] Print the `Type "backup now" exactly to proceed` prompt
- [ ] Read user input with `set /p CONFIRM=> `
- [ ] If `"%CONFIRM%"=="backup now"` proceed; otherwise print `Backup cancelled.` and `exit /b 0`
- [ ] Confirm comparison is case-sensitive per spec (use `if` with quoted strings)
## 7. Execute Backup
- [ ] Create `%DEST_ROOT%` via `mkdir` if it does not exist
- [ ] Define `LOG_FILE=%BACKUP_DRIVE%\backup_log_YYYY-MM-DD.txt`
- [ ] Run robocopy for Documents with flags `/E /XJ /R:1 /W:1 /TEE /LOG+:%LOG_FILE%`
- [ ] Run robocopy for Desktop with the same flags
- [ ] Run robocopy for Pictures with the same flags
- [ ] Run robocopy for Downloads with the same flags
- [ ] Capture robocopy exit codes; treat `>= 8` as failure (drive full / access denied)
## 8. Completion
- [ ] Print `Backup complete.` block with `%DEST_ROOT%` and `%LOG_FILE%` paths
- [ ] Remind user to review log for skipped files
- [ ] `pause >nul` on `Press any key to exit...`
- [ ] `exit /b 0`
## 9. Error Handling
- [ ] Missing marker file → error message + `exit /b 1`
- [ ] Missing source folder → warn and continue (do not abort)
- [ ] Robocopy exit code indicates drive full → print `Backup incomplete — drive may be full`
- [ ] Locked files → rely on robocopy log (no special handling)
## 10. Validation
- [ ] Test on a machine with a drive that has `.backup-target` at root
- [ ] Test the "no marker" path (error + exit 1)
- [ ] Test the "multiple markers" path (warning + uses first)
- [ ] Test cancellation path (anything other than `backup now`)
- [ ] Verify log file is created and populated after a real run
- [ ] Confirm script works in Safe Mode with Command Prompt
- [ ] Confirm no non-builtin commands are required
