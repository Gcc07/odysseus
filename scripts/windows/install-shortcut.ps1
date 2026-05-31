param(
    [switch]$AutoStart
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Launcher = Join-Path $PSScriptRoot "start-odysseus.bat"
$Desktop = [Environment]::GetFolderPath("Desktop")
$Startup = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $Desktop "Odysseus.lnk"

if (-not (Test-Path $Launcher)) {
    throw "Launcher not found: $Launcher"
}

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $Launcher
$Shortcut.WorkingDirectory = $ProjectRoot
$Shortcut.WindowStyle = 1
$Shortcut.Description = "Start Odysseus"
$Shortcut.Save()

Write-Host "Created desktop shortcut:"
Write-Host "  $ShortcutPath"

if ($AutoStart) {
    $StartupShortcut = Join-Path $Startup "Odysseus.lnk"
    Copy-Item -Path $ShortcutPath -Destination $StartupShortcut -Force
    Write-Host "Added to Windows Startup folder:"
    Write-Host "  $StartupShortcut"
    Write-Host "Odysseus will launch automatically when you sign in."
} else {
    Write-Host ""
    Write-Host "To also start Odysseus at login, run:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -AutoStart"
}
