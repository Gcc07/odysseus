# Stop Docker stack, then launch native Odysseus (GPU-friendly).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_switch-common.ps1"

$root = Get-OdysseusProjectRoot
Set-Location $root

Write-Host "Stopping Odysseus Docker stack..."
Stop-OdysseusDocker -ProjectRoot $root
Stop-OdysseusPort7000

if (-not (Wait-Port7000Free)) {
    Write-Warning "Port 7000 is still in use. Native start may fail."
}

$launcher = Join-Path $PSScriptRoot "start-odysseus.bat"
if (-not (Test-Path $launcher)) {
    throw "Native launcher not found: $launcher"
}

Write-Host "Starting native Odysseus..."
Start-Process -FilePath $launcher -WorkingDirectory $root

Write-Host ""
Write-Host "Mode: Native (GPU)  |  URL: http://localhost:7000"
Write-Host "A command window will stay open while the server runs."
