$ErrorActionPreference = "Stop"

function Get-OdysseusProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Stop-OdysseusPort7000 {
    $conns = Get-NetTCPConnection -LocalPort 7000 -State Listen -ErrorAction SilentlyContinue
    foreach ($conn in $conns) {
        Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

function Stop-OdysseusDocker {
    param([string]$ProjectRoot)
    Push-Location $ProjectRoot
    try {
        docker compose down 2>&1 | Out-Null
    } finally {
        Pop-Location
    }
}

function Wait-Port7000Free {
    param([int]$Seconds = 15)
    for ($i = 0; $i -lt $Seconds; $i++) {
        $busy = Get-NetTCPConnection -LocalPort 7000 -State Listen -ErrorAction SilentlyContinue
        if (-not $busy) { return $true }
        Start-Sleep -Seconds 1
    }
    return -not (Get-NetTCPConnection -LocalPort 7000 -State Listen -ErrorAction SilentlyContinue)
}

function Open-OdysseusBrowser {
    Start-Process "http://127.0.0.1:7000/"
}
