# Create desktop shortcuts for Docker / Native mode switching.
$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Desktop = [Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -ComObject WScript.Shell

$shortcuts = @(
    @{
        Name = "Odysseus (Docker)"
        Target = Join-Path $PSScriptRoot "switch-to-docker.bat"
        Description = "Stop native Odysseus and start the Docker stack"
    },
    @{
        Name = "Odysseus (Native GPU)"
        Target = Join-Path $PSScriptRoot "switch-to-native.bat"
        Description = "Stop Docker and start native Odysseus for local GPU use"
    }
)

foreach ($sc in $shortcuts) {
    $path = Join-Path $Desktop "$($sc.Name).lnk"
    $link = $WshShell.CreateShortcut($path)
    $link.TargetPath = $sc.Target
    $link.WorkingDirectory = $ProjectRoot
    $link.WindowStyle = 1
    $link.Description = $sc.Description
    $link.Save()
    Write-Host "Created: $path"
}

Write-Host ""
Write-Host "Use Odysseus (Docker) for the full bundled app."
Write-Host "Use Odysseus (Native GPU) for local GPU / Cookbook work."
