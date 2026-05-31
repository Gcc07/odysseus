# Probe the Windows host GPU/RAM, then start Odysseus in Docker.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)

& "$PSScriptRoot\write-host-hardware.ps1"
docker compose up -d --build

Write-Host ""
Write-Host "Odysseus: http://localhost:7000"
