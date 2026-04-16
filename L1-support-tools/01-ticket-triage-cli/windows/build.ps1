# Build script for ticket-triage Windows executable
# Requires: Python 3.10+, pip, pyinstaller

param(
    [switch]$Clean,
    [switch]$InstallDeps,
    [switch]$Test
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===`n" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Header "Ticket Triage Build Script"

# Clean previous builds
if ($Clean) {
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    Remove-Item -Path "build", "dist" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Clean complete." -ForegroundColor Green
}

# Install dependencies
if ($InstallDeps) {
    Write-Header "Installing Dependencies"
    
    Write-Host "Installing pyinstaller..." -ForegroundColor Yellow
    pip install pyinstaller
    
    Write-Host "Installing package in editable mode..." -ForegroundColor Yellow
    pip install -e .
}

# Verify pyinstaller is available
if (-not (Test-Command "pyinstaller")) {
    Write-Error "PyInstaller not found. Install with: pip install pyinstaller"
    exit 1
}

# Build executable
Write-Header "Building Executable"

pyinstaller ticket-triage.spec --clean --noconfirm

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit 1
}

# Verify build output
$exePath = Join-Path $scriptDir "dist\ticket-triage.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "Build output not found: $exePath"
    exit 1
}

$exeSize = (Get-Item $exePath).Length / 1MB
Write-Host "`nBuild successful!" -ForegroundColor Green
Write-Host "  Executable: $exePath" -ForegroundColor Gray
Write-Host "  Size: $([math]::Round($exeSize, 2)) MB" -ForegroundColor Gray

# Run tests if requested
if ($Test) {
    Write-Header "Running Tests"
    
    # Test help
    Write-Host "Testing --help..." -ForegroundColor Yellow
    & $exePath --help
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Help test failed"
        exit 1
    }
    
    # Test version
    Write-Host "Testing --version..." -ForegroundColor Yellow
    & $exePath --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Version test failed"
        exit 1
    }
    
    # Test with pipe
    Write-Host "Testing with pipe..." -ForegroundColor Yellow
    $testOutput = "Password expired" | & $exePath
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
        Write-Error "Pipe test failed with exit code $LASTEXITCODE"
        exit 1
    }
    Write-Host $testOutput
    
    Write-Host "`nAll tests passed!" -ForegroundColor Green
}

Write-Host "`nBuild complete. Distribute dist\ticket-triage.exe" -ForegroundColor Cyan
