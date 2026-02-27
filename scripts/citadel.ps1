<#
.SYNOPSIS
    Dotfiles Citadel — Performance & Stability Forge (citadel.ps1)

.DESCRIPTION
    Hardens a Windows 11 + WSL2 workstation running on an AMD Ryzen AI 7
    with 16 GB RAM against system-wide memory exhaustion and VS Code / WSL2
    instability.  Run this script once after a fresh OS install or whenever
    performance degrades.

    Actions performed:
      1. Validates that .wslconfig is in place with a 6 GB memory cap.
      2. Applies VS Code workspace/extension memory-safety recommendations
         to vscode/settings.json.
      3. Disables Windows Search indexing on the workspace NTFS volume.
      4. Configures Power Plan to "Balanced" (avoids thermal throttle on
         sustained coding workloads with the Ryzen AI 7).
      5. Prints a health summary.

.PARAMETER DryRun
    Print what would happen without making any changes.

.PARAMETER WorkspaceDrive
    Drive letter of the workspace NTFS volume (default: C).

.EXAMPLE
    pwsh -File scripts\citadel.ps1
    pwsh -File scripts\citadel.ps1 -DryRun
    pwsh -File scripts\citadel.ps1 -WorkspaceDrive D

.NOTES
    Author:  geekedsilicon
    Version: 1.0.0
    Requires: PowerShell 7+, Windows 11, Administrator privileges for some steps.
#>

# @param {switch} DryRun          No filesystem or registry changes when set.
# @param {string} WorkspaceDrive  NTFS drive letter to tune (default: C).
param(
    [switch]$DryRun,
    [string]$WorkspaceDrive = 'C'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<# @const {string} DOTFILES_DIR  Repository root. #>
$DOTFILES_DIR = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

function Write-Info  { param($Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan   }
function Write-Ok    { param($Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green  }
function Write-Warn  { param($Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param($Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red    }
function Write-Head  { param($Msg) Write-Host "`n===  $Msg  ===" -ForegroundColor Magenta }

if ($DryRun) { Write-Warn "DRY-RUN mode — no changes will be written." }

# ---------------------------------------------------------------------------
# @function Assert-WslConfig
# @description  Verifies that C:\Users\<user>\.wslconfig contains the
#               memory cap recommended for a 16 GB system (≤ 6 GB for WSL).
#               Copies the repo's .wslconfig if the user file is absent.
# ---------------------------------------------------------------------------
function Assert-WslConfig {
    Write-Head "WSL2 Resource Governor"

    $dest = "$env:USERPROFILE\.wslconfig"
    $src  = Join-Path $DOTFILES_DIR '.wslconfig'

    if (-not (Test-Path $dest)) {
        Write-Warn ".wslconfig not found at $dest"
        if (Test-Path $src) {
            Write-Info "Copying repo .wslconfig -> $dest"
            if (-not $DryRun) { Copy-Item $src $dest -Force }
            Write-Ok  "Copied.  Run: wsl --shutdown  to apply the new limits."
        } else {
            Write-Err "No .wslconfig in repo either.  Please create one."
        }
        return
    }

    $content = Get-Content $dest -Raw
    if ($content -match 'memory\s*=\s*(\d+)GB') {
        $memGB = [int]$Matches[1]
        if ($memGB -le 6) {
            Write-Ok ".wslconfig memory cap: ${memGB} GB  ✓"
        } else {
            Write-Warn ".wslconfig memory cap is ${memGB} GB — consider lowering to 6 GB."
        }
    } else {
        Write-Warn ".wslconfig found but no 'memory' key detected."
    }
}

# ---------------------------------------------------------------------------
# @function Set-VSCodeMemorySafety
# @description  Patches vscode/settings.json with memory-safety and
#               Ryzen-stability settings, preserving existing keys.
# ---------------------------------------------------------------------------
function Set-VSCodeMemorySafety {
    Write-Head "VS Code Memory-Safety Patch"

    $settingsPath = Join-Path $DOTFILES_DIR 'vscode\settings.json'

    if (-not (Test-Path $settingsPath)) {
        Write-Warn "vscode/settings.json not found — skipping."
        return
    }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable

    # Memory / performance guards
    $patch = @{
        'files.watcherExclude'                         = @{
            '**/.git/objects/**' = $true
            '**/node_modules/**' = $true
            '**/dist/**'         = $true
        }
        'search.followSymlinks'                        = $false
        'extensions.autoUpdate'                        = $false
        'telemetry.telemetryLevel'                     = 'off'
        'editor.largeFileOptimizations'                = $true
        'files.maxMemoryForLargeFilesMB'               = 256
        'window.restoreWindows'                        = 'none'
        'git.autofetch'                                = $false
    }

    $changed = $false
    foreach ($key in $patch.Keys) {
        if (-not $settings.ContainsKey($key)) {
            $settings[$key] = $patch[$key]
            $changed = $true
            Write-Info "  + $key"
        }
    }

    if ($changed -and -not $DryRun) {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Ok "vscode/settings.json updated."
    } elseif (-not $changed) {
        Write-Ok "vscode/settings.json already has all safety keys."
    }
}

# ---------------------------------------------------------------------------
# @function Disable-SearchIndexingOnWorkspace
# @description  Removes the workspace volume from Windows Search indexing to
#               prevent the indexer from spiking I/O during coding sessions.
# ---------------------------------------------------------------------------
function Disable-SearchIndexingOnWorkspace {
    Write-Head "Windows Search Indexing"

    $volumePath = "${WorkspaceDrive}:\"

    # Check if running with sufficient privileges.
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Write-Warn "Not running as Administrator — skipping Search index change."
        return
    }

    try {
        $service = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter='${WorkspaceDrive}:'" -ErrorAction Stop
        if ($null -eq $service) {
            Write-Warn "Volume ${WorkspaceDrive}: not found via WMI."
            return
        }
        if ($service.IndexingEnabled -eq $false) {
            Write-Ok "Indexing already disabled on ${WorkspaceDrive}:\"
            return
        }
        Write-Info "Disabling Search indexing on ${WorkspaceDrive}:\"
        if (-not $DryRun) {
            $service.IndexingEnabled = $false
            $service.Put() | Out-Null
        }
        Write-Ok "Indexing disabled on ${WorkspaceDrive}:\"
    } catch {
        Write-Warn "Could not modify Search indexing: $_"
    }
}

# ---------------------------------------------------------------------------
# @function Set-BalancedPowerPlan
# @description  Activates the Balanced power plan, which avoids Ryzen AI 7
#               thermal throttling under sustained workloads (High Performance
#               keeps all cores hot even when idle, causing temperature spikes).
# ---------------------------------------------------------------------------
function Set-BalancedPowerPlan {
    Write-Head "Power Plan"

    $balanced = powercfg /list 2>$null |
        Select-String 'Balanced' |
        ForEach-Object { ($_ -split '\s+')[3] } |
        Select-Object -First 1

    if ($null -eq $balanced -or $balanced -eq '') {
        Write-Warn "Balanced power plan GUID not found."
        return
    }

    Write-Info "Activating Balanced plan: $balanced"
    if (-not $DryRun) { powercfg /setactive $balanced }
    Write-Ok "Power plan set to Balanced."
}

# ---------------------------------------------------------------------------
# @function Write-HealthSummary
# @description  Prints a concise health report for the workstation.
# ---------------------------------------------------------------------------
function Write-HealthSummary {
    Write-Head "Health Summary"

    # WSL version
    try {
        $wslVer = (wsl --version 2>$null | Select-String 'WSL version' | Select-Object -First 1).ToString().Trim()
        Write-Ok "WSL  : $wslVer"
    } catch {
        Write-Warn "WSL  : could not query version"
    }

    # Available RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $usedGB  = [math]::Round($totalGB - $freeGB, 1)
    Write-Ok "RAM  : ${usedGB} GB used / ${totalGB} GB total  (${freeGB} GB free)"

    # Disk
    $disk = Get-PSDrive -Name $WorkspaceDrive -ErrorAction SilentlyContinue
    if ($disk) {
        $usedDiskGB = [math]::Round(($disk.Used) / 1GB, 1)
        $freeDiskGB = [math]::Round(($disk.Free) / 1GB, 1)
        Write-Ok "Disk : ${WorkspaceDrive}: — ${usedDiskGB} GB used, ${freeDiskGB} GB free"
    }

    Write-Host ""
    Write-Ok "Citadel forge complete."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function Main {
    Write-Info "Dotfiles Citadel — Performance & Stability Forge"
    Write-Info "Repository root : $DOTFILES_DIR"

    Assert-WslConfig
    Set-VSCodeMemorySafety
    Disable-SearchIndexingOnWorkspace
    Set-BalancedPowerPlan
    Write-HealthSummary
}

Main
