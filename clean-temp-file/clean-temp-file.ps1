# Description: Clean temp files from the system.
# Automate cleanup on a local machine or deploy it across multiple systems to maintain performance.
$tempFolders = @("$env:TEMP", "C:\Windows\Temp")
foreach ($folder in $tempFolders) {
    Write-Host "Cleaning $folder..."
    Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | 
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Done cleaning $folder."
}