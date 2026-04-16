#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installation script for AD/User Provisioning CLI (Windows)
.DESCRIPTION
    Installs the ad-provision PowerShell module to the user's modules directory
    and optionally creates the configuration directory structure.
.EXAMPLE
    .\install.ps1
    Installs the module to the default PowerShell modules path.
.EXAMPLE
    .\install.ps1 -SkipConfig
    Installs the module without creating config directories.
.EXAMPLE
    .\install.ps1 -Force
    Force reinstall if module already exists.
#>
[CmdletBinding()]
param(
    [switch]$SkipConfig,
    [switch]$Force
)

$ModuleName = "ad-provision"
$SourcePath = $PSScriptRoot
$DestinationPath = Join-Path $env:Documents "PowerShell\Modules\$ModuleName"

Write-Host "AD/User Provisioning CLI - Installation" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This module requires PowerShell 7.0 or later. You are running $($PSVersionTable.PSVersion)"
    Write-Host "Install PowerShell 7: winget install Microsoft.PowerShell" -ForegroundColor Yellow
    exit 1
}

# Check if destination exists
if (Test-Path $DestinationPath) {
    if (-not $Force) {
        Write-Warning "Module already installed at: $DestinationPath"
        $response = Read-Host "Overwrite existing installation? (y/N)"
        if ($response -notin @('y', 'Y', 'yes', 'YES')) {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $DestinationPath
}

# Create destination directory
Write-Host "Creating module directory: $DestinationPath" -ForegroundColor Green
New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

# Copy module files
$filesToCopy = @(
    "ad-provision.psd1"
    "ad-provision.psm1"
)

$directoriesToCopy = @(
    "public"
    "private"
    "config"
)

foreach ($file in $filesToCopy) {
    $source = Join-Path $SourcePath $file
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $DestinationPath -Force
        Write-Host "  Copied: $file" -ForegroundColor Gray
    }
}

foreach ($dir in $directoriesToCopy) {
    $source = Join-Path $SourcePath $dir
    if (Test-Path $source) {
        $dest = Join-Path $DestinationPath $dir
        Copy-Item -Recurse -Path $source -Destination $dest -Force
        Write-Host "  Copied: $dir/" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Module installed successfully!" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Cyan

$requiredModules = @(
    @{ Name = "Microsoft.Graph.Users"; MinimumVersion = "2.0.0" }
    @{ Name = "Microsoft.Graph.Groups"; MinimumVersion = "2.0.0" }
    @{ Name = "ExchangeOnlineManagement"; MinimumVersion = "3.0.0" }
    @{ Name = "Pester"; MinimumVersion = "5.0.0" }
)

foreach ($module in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $module.Name | 
        Where-Object { $_.Version -ge $module.MinimumVersion }
    
    if ($installed) {
        Write-Host "  [OK] $($module.Name) (v$($installed[0].Version))" -ForegroundColor Green
    }
    else {
        Write-Host "  [MISSING] $($module.Name) (requires v$($module.MinimumVersion)+)" -ForegroundColor Yellow
        $response = Read-Host "Install $($module.Name)? (Y/n)"
        if ($response -in @('', 'y', 'Y', 'yes', 'YES')) {
            try {
                Install-Module -Name $module.Name -Scope CurrentUser -MinimumVersion $module.MinimumVersion -Force
                Write-Host "    Installed $($module.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to install $($module.Name): $_"
            }
        }
    }
}

# Create config directory
if (-not $SkipConfig) {
    Write-Host ""
    Write-Host "Configuration Setup" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $configDir = Join-Path $env:APPDATA "ad-provision"
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Host "Created config directory: $configDir" -ForegroundColor Green
    }
    
    $configFile = Join-Path $configDir "creds.env"
    $exampleFile = Join-Path $SourcePath "config\creds.env.example"
    
    if (-not (Test-Path $configFile) -and (Test-Path $exampleFile)) {
        Copy-Item -Path $exampleFile -Destination $configFile
        Write-Host "Created config template: $configFile" -ForegroundColor Yellow
        Write-Host "  Please edit this file with your Azure AD credentials." -ForegroundColor Yellow
    }
    elseif (Test-Path $configFile) {
        Write-Host "Config file already exists: $configFile" -ForegroundColor Green
    }
}

# Test module import
Write-Host ""
Write-Host "Testing module import..." -ForegroundColor Cyan

try {
    Import-Module $ModuleName -Force -ErrorAction Stop
    Write-Host "  [OK] Module imported successfully" -ForegroundColor Green
    
    $commands = @(
        'New-ADProvisionUser'
        'Add-ADProvisionGroup'
        'Enable-ADProvisionMailbox'
        'Reset-ADProvisionPassword'
        'Remove-ADProvisionUser'
    )
    
    foreach ($cmd in $commands) {
        if (Get-Command -Module $ModuleName -Name $cmd -ErrorAction SilentlyContinue) {
            Write-Host "    [OK] $cmd" -ForegroundColor Gray
        }
        else {
            Write-Host "    [FAIL] $cmd not found" -ForegroundColor Red
        }
    }
}
catch {
    Write-Warning "Failed to import module: $_"
}

# Final output
Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit your config: notepad '$env:APPDATA\ad-provision\creds.env'"
Write-Host "  2. Run tests: Invoke-Pester '$DestinationPath\tests'"
Write-Host "  3. Start provisioning: New-ADProvisionUser -?"
Write-Host ""
Write-Host "For more information: Get-Help about_ad-provision" -ForegroundColor Gray
