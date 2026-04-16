@echo off
setlocal EnableDelayedExpansion

::=========================================================
:: Windows Pre-reformat Backup v1.0
:: Author: Mchael Poncardas (poncardas.com)
:: Purpose: One-time pre-reformat backup of user data to an
::          external drive identified by a marker file.
::          Uses only built-in Windows commands (batch + robocopy).
::=========================================================

:: === CONFIGURATION ===
:: Marker filename on external drive (create this file at root of your backup drive)
set "MARKER_FILE=.backup-target"

:: Optional: add custom folders here if needed (one per line)
:: set "EXTRA_FOLDER_1=%USERPROFILE%\Music"
:: === END CONFIGURATION ===


::---------------------------------------------------------
:: Step 1: Intro Banner
::---------------------------------------------------------
cls
echo ====================================
echo WINDOWS USER DATA BACKUP v1.0
echo by Mchael Poncardas (poncardas.com)
echo ====================================
echo.
echo This script will:
echo 1. Detect your external backup drive
echo 2. Scan your Documents, Desktop, Pictures, and Downloads folders
echo 3. Show total files and size to be backed up
echo 4. Preview what will be copied
echo 5. Ask for explicit confirmation before starting
echo 6. Copy files using robocopy with logging
echo.
echo Press any key to continue...
pause >nul


::---------------------------------------------------------
:: Step 2: External Drive Detection
::---------------------------------------------------------
set "BACKUP_DRIVE="
set "EXTRA_MARKERS="

for %%D in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\%MARKER_FILE%" (
        if not defined BACKUP_DRIVE (
            set "BACKUP_DRIVE=%%D:"
        ) else (
            set "EXTRA_MARKERS=!EXTRA_MARKERS! %%D:"
        )
    )
)

if not defined BACKUP_DRIVE (
    echo.
    echo [ERROR] No external drive with marker file "%MARKER_FILE%" was found.
    echo         Create an empty file named "%MARKER_FILE%" at the root of your
    echo         backup drive ^(e.g. E:\%MARKER_FILE%^) and run this script again.
    echo.
    pause
    exit /b 1
)

if defined EXTRA_MARKERS (
    echo.
    echo [WARNING] Multiple drives have the marker file. Using %BACKUP_DRIVE%.
    echo           Also found on:!EXTRA_MARKERS!
    echo.
)

echo.
echo Detected backup drive: %BACKUP_DRIVE%
echo.


::---------------------------------------------------------
:: Step 3: Source Folder Definition
::---------------------------------------------------------
set "SRC_DOCUMENTS=%USERPROFILE%\Documents"
set "SRC_DESKTOP=%USERPROFILE%\Desktop"
set "SRC_PICTURES=%USERPROFILE%\Pictures"
set "SRC_DOWNLOADS=%USERPROFILE%\Downloads"


::---------------------------------------------------------
:: Compute locale-independent YYYY-MM-DD date stamp
::---------------------------------------------------------
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "DATESTAMP=%%A"

set "DEST_ROOT=%BACKUP_DRIVE%\Backup_%DATESTAMP%"
set "LOG_FILE=%BACKUP_DRIVE%\backup_log_%DATESTAMP%.txt"


::---------------------------------------------------------
:: Step 4: Size Calculation
::---------------------------------------------------------
set /a TOTAL_FILES=0
set "TOTAL_BYTES=0"

call :measure "Documents" "%SRC_DOCUMENTS%" DOC_FILES DOC_BYTES
call :measure "Desktop"   "%SRC_DESKTOP%"   DSK_FILES DSK_BYTES
call :measure "Pictures"  "%SRC_PICTURES%"  PIC_FILES PIC_BYTES
call :measure "Downloads" "%SRC_DOWNLOADS%" DLD_FILES DLD_BYTES

call :addBytes "%TOTAL_BYTES%" "%DOC_BYTES%" TOTAL_BYTES
call :addBytes "%TOTAL_BYTES%" "%DSK_BYTES%" TOTAL_BYTES
call :addBytes "%TOTAL_BYTES%" "%PIC_BYTES%" TOTAL_BYTES
call :addBytes "%TOTAL_BYTES%" "%DLD_BYTES%" TOTAL_BYTES

set /a TOTAL_FILES=DOC_FILES+DSK_FILES+PIC_FILES+DLD_FILES

call :bytesToGB "%DOC_BYTES%"   DOC_GB
call :bytesToGB "%DSK_BYTES%"   DSK_GB
call :bytesToGB "%PIC_BYTES%"   PIC_GB
call :bytesToGB "%DLD_BYTES%"   DLD_GB
call :bytesToGB "%TOTAL_BYTES%" TOTAL_GB

echo.
echo BACKUP SUMMARY
echo --------------
echo Documents:   %DOC_FILES% files, %DOC_GB% GB
echo Desktop:     %DSK_FILES% files, %DSK_GB% GB
echo Pictures:    %PIC_FILES% files, %PIC_GB% GB
echo Downloads:   %DLD_FILES% files, %DLD_GB% GB
echo --------------
echo TOTAL:       %TOTAL_FILES% files, %TOTAL_GB% GB
echo DESTINATION: %DEST_ROOT%\
echo.


::---------------------------------------------------------
:: Step 5: Dry-Run Preview
::---------------------------------------------------------
echo DRY-RUN PREVIEW (no files copied yet)
echo -------------------------------------

call :dryrun "Documents" "%SRC_DOCUMENTS%" "%DEST_ROOT%\Documents"
call :dryrun "Desktop"   "%SRC_DESKTOP%"   "%DEST_ROOT%\Desktop"
call :dryrun "Pictures"  "%SRC_PICTURES%"  "%DEST_ROOT%\Pictures"
call :dryrun "Downloads" "%SRC_DOWNLOADS%" "%DEST_ROOT%\Downloads"

echo.


::---------------------------------------------------------
:: Step 6: Explicit Confirmation
::---------------------------------------------------------
echo Type "backup now" exactly to proceed with the backup.
echo Any other input will cancel.
echo.
set "CONFIRM="
set /p "CONFIRM=> "

if not "%CONFIRM%"=="backup now" (
    echo.
    echo Backup cancelled.
    exit /b 0
)


::---------------------------------------------------------
:: Step 7: Execute Backup
::---------------------------------------------------------
if not exist "%DEST_ROOT%" mkdir "%DEST_ROOT%"

set "ROBO_FLAGS=/E /XJ /R:1 /W:1 /TEE /LOG+:%LOG_FILE%"
set /a MAX_RC=0

call :backup "Documents" "%SRC_DOCUMENTS%" "%DEST_ROOT%\Documents"
call :backup "Desktop"   "%SRC_DESKTOP%"   "%DEST_ROOT%\Desktop"
call :backup "Pictures"  "%SRC_PICTURES%"  "%DEST_ROOT%\Pictures"
call :backup "Downloads" "%SRC_DOWNLOADS%" "%DEST_ROOT%\Downloads"

if %MAX_RC% GEQ 8 (
    echo.
    echo [ERROR] Backup incomplete -- drive may be full or access denied.
    echo         Review the log: %LOG_FILE%
    echo.
    pause
    exit /b %MAX_RC%
)


::---------------------------------------------------------
:: Step 8: Completion
::---------------------------------------------------------
echo.
echo Backup complete.
echo Files copied to: %DEST_ROOT%
echo Log file: %LOG_FILE%
echo.
echo Review the log for any skipped files.
echo Press any key to exit...
pause >nul
exit /b 0


::=========================================================
:: SUBROUTINES
::=========================================================

:measure <Label> <Path> <OutFilesVar> <OutBytesVar>
::  Measures file count and byte size of a folder. If folder missing, warns
::  and returns zeros.
set "_LABEL=%~1"
set "_PATH=%~2"
set "_OUT_FILES=%~3"
set "_OUT_BYTES=%~4"

if not exist "%_PATH%" (
    echo [WARN] Source folder missing, will skip: %_PATH%
    set "%_OUT_FILES%=0"
    set "%_OUT_BYTES%=0"
    goto :eof
)

set "_FILES=0"
set "_BYTES=0"

for /f "tokens=1,3 delims= " %%A in ('dir /s /a:-d /-c "%_PATH%" 2^>nul ^| findstr /C:"File(s)"') do (
    set "_FILES=%%A"
    set "_BYTES=%%B"
)

:: Strip commas from numbers just in case
set "_FILES=%_FILES:,=%"
set "_BYTES=%_BYTES:,=%"

if "%_FILES%"=="" set "_FILES=0"
if "%_BYTES%"=="" set "_BYTES=0"

set "%_OUT_FILES%=%_FILES%"
set "%_OUT_BYTES%=%_BYTES%"
goto :eof


:addBytes <A> <B> <OutVar>
::  Adds two decimal byte counts using PowerShell to avoid 32-bit overflow
::  in cmd.exe's set /a.
for /f %%R in ('powershell -NoProfile -Command "[int64]%~1 + [int64]%~2"') do set "%~3=%%R"
goto :eof


:bytesToGB <Bytes> <OutVar>
::  Converts a byte count to GB with 2 decimals (1 GB = 1024^3 bytes).
for /f %%R in ('powershell -NoProfile -Command "[math]::Round([int64]%~1 / 1GB, 2)"') do set "%~2=%%R"
goto :eof


:dryrun <Label> <Src> <Dst>
set "_LABEL=%~1"
set "_SRC=%~2"
set "_DST=%~3"

if not exist "%_SRC%" (
    echo %_LABEL%: [skipped -- source missing]
    goto :eof
)

echo.
echo --- %_LABEL% ---
robocopy "%_SRC%" "%_DST%" /E /XJ /L /NFL /NDL /NJH /NP /NS /NC
goto :eof


:backup <Label> <Src> <Dst>
set "_LABEL=%~1"
set "_SRC=%~2"
set "_DST=%~3"

if not exist "%_SRC%" (
    echo [WARN] Skipping %_LABEL%: source missing (%_SRC%)
    goto :eof
)

echo.
echo === Copying %_LABEL% ===
robocopy "%_SRC%" "%_DST%" %ROBO_FLAGS%
set "_RC=%ERRORLEVEL%"

if %_RC% GTR %MAX_RC% set /a MAX_RC=%_RC%
goto :eof
