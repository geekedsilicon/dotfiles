<#
.SYNOPSIS
    Dotfiles Citadel — Windows/PowerShell symlink installer.

.DESCRIPTION
    Creates symbolic links from this repository to their live Windows system
    locations: PowerShell profile, VS Code AppData settings, and cmd AutoRun.
    Handles Developer Mode requirements and ensures every target directory
    exists before linking.

    The repository is assumed to live at
    C:\Users\<WIN_USER>\workspace\dotfiles

.PARAMETER DryRun
    Print what would happen without making any changes.

.EXAMPLE
    pwsh -File scripts\setup.ps1
    pwsh -File scripts\setup.ps1 -DryRun

.NOTES
    Author:  geekedsilicon
    Version: 1.0.0
    Requires: PowerShell 7+ (pwsh) recommended; Windows PowerShell 5.1 supported.
    Run as your normal user — symlink creation requires Developer Mode or
    elevation on Windows 10/11.
#>

# @param {switch} DryRun  When present, no filesystem changes are made.
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve repository root (parent of the scripts\ directory)
# ---------------------------------------------------------------------------

<# @const {string} DOTFILES_DIR  Absolute path of the repository root. #>
$DOTFILES_DIR = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# ---------------------------------------------------------------------------
# Colour/logging helpers
# ---------------------------------------------------------------------------

function Write-Info    { param($Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan   }
function Write-Ok      { param($Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green  }
function Write-Warn    { param($Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err     { param($Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red    }

if ($DryRun) { Write-Warn "DRY-RUN mode — no changes will be written." }

# ---------------------------------------------------------------------------
# @function New-Symlink
# @description  Creates a symbolic link from $Source to $Destination.
#               Backs up any pre-existing regular file at $Destination and
#               ensures the parent directory exists.
# @param {string} Source       Absolute source path inside the dotfiles repo.
# @param {string} Destination  Absolute path of the live system target.
# ---------------------------------------------------------------------------
function New-Symlink {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    # Verify source exists.
    if (-not (Test-Path $Source)) {
        Write-Warn "Source not found, skipping: $Source"
        return
    }

    $destDir = Split-Path -Parent $Destination

    # Ensure parent directory exists.
    if (-not (Test-Path $destDir)) {
        Write-Info "Creating directory: $destDir"
        if (-not $DryRun) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    }

    # Back up existing regular file; remove stale symlink.
    if ((Test-Path $Destination) -and -not (Get-Item $Destination).LinkType) {
        $backup = "$Destination.bak.$(Get-Date -Format 'yyyyMMddTHHmmss')"
        Write-Warn "Backing up existing file: $Destination -> $backup"
        if (-not $DryRun) { Move-Item -Path $Destination -Destination $backup }
    } elseif (Test-Path $Destination) {
        Write-Warn "Removing stale symlink: $Destination"
        if (-not $DryRun) { Remove-Item -Path $Destination -Force }
    }

    Write-Info "Linking: $Source -> $Destination"
    if (-not $DryRun) {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    }
    Write-Ok "Linked: $Destination"
}

# ---------------------------------------------------------------------------
# @function Set-GitFilemodeHardening
# @description  Sets git core.filemode = false so NTFS mounts do not
#               produce spurious executable-bit diffs.
# ---------------------------------------------------------------------------
function Set-GitFilemodeHardening {
    Write-Info "Setting git core.filemode = false (NTFS hardening)"
    if (-not $DryRun) { git -C $DOTFILES_DIR config core.filemode false }
    Write-Ok "core.filemode = false"
}

# ---------------------------------------------------------------------------
# @function Register-PowerShellProfiles
# @description  Links the shared PowerShell profile to both PS 7 and PS 5.1.
# ---------------------------------------------------------------------------
function Register-PowerShellProfiles {
    Write-Info "=== PowerShell profiles ==="

    $src = Join-Path $DOTFILES_DIR 'powershell\Microsoft.PowerShell_profile.ps1'

    # PowerShell 7 (pwsh)
    New-Symlink -Source $src `
                -Destination "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

    # Windows PowerShell 5.1
    New-Symlink -Source $src `
                -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
}

# ---------------------------------------------------------------------------
# @function Register-VSCodeSettings
# @description  Links VS Code user settings.json from AppData to the repo.
# ---------------------------------------------------------------------------
function Register-VSCodeSettings {
    Write-Info "=== VS Code settings ==="
    New-Symlink -Source (Join-Path $DOTFILES_DIR 'vscode\settings.json') `
                -Destination "$env:APPDATA\Code\User\settings.json"
}

# ---------------------------------------------------------------------------
# @function Register-WslConfig
# @description  Copies (or links) .wslconfig to the Windows user home so WSL2
#               respects the memory governor on next restart.
# ---------------------------------------------------------------------------
function Register-WslConfig {
    Write-Info "=== .wslconfig (WSL2 resource governor) ==="
    $src  = Join-Path $DOTFILES_DIR '.wslconfig'
    $dest = "$env:USERPROFILE\.wslconfig"

    # .wslconfig must be a real file (WSL reads it before NTFS symlinks resolve).
    if (Test-Path $src) {
        if (-not $DryRun) { Copy-Item -Path $src -Destination $dest -Force }
        Write-Ok "Copied .wslconfig -> $dest  (restart WSL to apply: wsl --shutdown)"
    } else {
        Write-Warn "No .wslconfig found in repo root; skipping."
    }
}

# ---------------------------------------------------------------------------
# @function Register-CmdAutoRun
# @description  Sets the HKCU cmd AutoRun registry key to source cmd_profile.cmd
#               on every cmd.exe launch.
# ---------------------------------------------------------------------------
function Register-CmdAutoRun {
    Write-Info "=== cmd AutoRun ==="
    $cmdProfile = Join-Path $DOTFILES_DIR 'cmd\cmd_profile.cmd'
    if (-not $DryRun) {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' `
                         -Name 'AutoRun' -Value $cmdProfile -Type String
    }
    Write-Ok "cmd AutoRun -> $cmdProfile"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function Main {
    Write-Info "Dotfiles Citadel — setup starting"
    Write-Info "Repository root: $DOTFILES_DIR"

    Set-GitFilemodeHardening
    Register-PowerShellProfiles
    Register-VSCodeSettings
    Register-WslConfig
    Register-CmdAutoRun

    Write-Ok "Setup complete.  Restart your terminal to apply all changes."
}

Main
