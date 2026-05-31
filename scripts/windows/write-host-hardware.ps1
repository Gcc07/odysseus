# Write Windows host hardware to data/host_hardware.json so Odysseus in Docker
# can show the real GPU/RAM (Linux containers cannot see the Windows GPU).
param(
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $OutFile) {
    $OutFile = Join-Path $root "data\host_hardware.json"
}

function Get-RegistryGpuVramGb([string]$Name) {
    $regBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if (-not (Test-Path $regBase)) { return $null }
    foreach ($key in Get-ChildItem $regBase -ErrorAction SilentlyContinue) {
        $p = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
        if (-not $p.DriverDesc) { continue }
        if ($Name -and $p.DriverDesc -ne $Name) { continue }
        $qw = $p.'HardwareInformation.qwMemorySize'
        if ($qw -and [uint64]$qw -gt 0) {
            return [math]::Round([uint64]$qw / 1GB, 1)
        }
    }
    return $null
}

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

$result = [ordered]@{
    total_ram_gb     = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    available_ram_gb = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    cpu_cores        = [int]$cores
    cpu_name         = [string]$cpu.Name
    has_gpu          = $false
    gpu_name         = $null
    gpu_vram_gb      = $null
    gpu_count        = 0
    backend          = "cpu_x86"
    gpus             = @()
    gpu_groups       = @()
    homogeneous      = $true
    hardware_source  = "host"
    updated_at       = [int][double]::Parse((Get-Date -UFormat %s))
}

$gpus = @()

# NVIDIA via nvidia-smi when available.
try {
    $nv = & nvidia-smi --query-gpu=memory.total,name --format=csv,noheader,nounits 2>$null
    if ($LASTEXITCODE -eq 0 -and $nv) {
        $idx = 0
        foreach ($line in ($nv -split "`n")) {
            if (-not $line.Trim()) { continue }
            $p = $line -split ','
            if ($p.Count -lt 2) { continue }
            $vramMb = [double]$p[0].Trim()
            $name = $p[1].Trim()
            $gpus += @{
                index   = $idx
                name    = $name
                vram_gb = [math]::Round($vramMb / 1024, 1)
            }
            $idx++
        }
        if ($gpus.Count -gt 0) {
            $result.backend = "cuda"
        }
    }
} catch {}

# AMD / other GPUs via WMI + registry VRAM fallback.
if ($gpus.Count -eq 0) {
    $wmiGpus = Get-CimInstance Win32_VideoController |
        Where-Object { $_.Name -and $_.Name -notmatch 'Microsoft|Remote|Basic' }
    $idx = 0
    foreach ($gpu in $wmiGpus) {
        $vramGb = Get-RegistryGpuVramGb -Name $gpu.Name
        if (-not $vramGb -and $gpu.AdapterRAM -gt 0) {
            $vramGb = [math]::Round([uint64]$gpu.AdapterRAM / 1GB, 1)
        }
        if (-not $vramGb) { continue }
        $gpus += @{
            index   = $idx
            name    = [string]$gpu.Name
            vram_gb = [double]$vramGb
        }
        $idx++
    }
    if ($gpus.Count -gt 0) {
        $result.backend = "cpu_x86"
    }
}

if ($gpus.Count -gt 0) {
    $totalVram = [math]::Round(($gpus | ForEach-Object { [double]$_.vram_gb } | Measure-Object -Sum).Sum, 1)
    $result.has_gpu = $true
    $result.gpu_name = $gpus[0].name
    $result.gpu_vram_gb = $totalVram
    $result.gpu_count = $gpus.Count
    $result.gpus = $gpus
    $each = [math]::Round($totalVram / $gpus.Count, 1)
    $result.gpu_groups = @(@{
        name       = $result.gpu_name
        vram_each  = $each
        count      = $gpus.Count
        indices    = @(0..($gpus.Count - 1))
        vram_total = $totalVram
    })
}

$dir = Split-Path $OutFile -Parent
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$json = $result | ConvertTo-Json -Depth 6 -Compress
[System.IO.File]::WriteAllText($OutFile, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Wrote host hardware profile:"
Write-Host "  $OutFile"
if ($result.has_gpu) {
    Write-Host ("  GPU: {0} ({1} GB)" -f $result.gpu_name, $result.gpu_vram_gb)
} else {
    Write-Host "  GPU: none detected"
}
Write-Host ("  RAM: {0} GB total" -f $result.total_ram_gb)
