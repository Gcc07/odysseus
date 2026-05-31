# Stop native Odysseus, refresh host hardware profile, start Docker stack.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_switch-common.ps1"

$root = Get-OdysseusProjectRoot
Set-Location $root

Write-Host "Stopping native Odysseus on port 7000..."
Stop-OdysseusPort7000
Start-Sleep -Seconds 1

Write-Host "Updating host hardware profile for What Fits?..."
& "$PSScriptRoot\write-host-hardware.ps1"

Write-Host "Starting Odysseus in Docker..."
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    throw "docker compose up failed (exit $LASTEXITCODE)"
}

Write-Host "Waiting for http://localhost:7000 ..."
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:7000/" -UseBasicParsing -TimeoutSec 2
        if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}

if ($ready) {
    Write-Host "Odysseus (Docker) is running."
    Open-OdysseusBrowser
} else {
    Write-Host "Containers started, but the app is still warming up."
    Write-Host "Check logs: docker compose logs -f odysseus"
    Open-OdysseusBrowser
}

Write-Host ""
Write-Host "Mode: Docker  |  URL: http://localhost:7000"
Write-Host "Stop with: docker compose down"
