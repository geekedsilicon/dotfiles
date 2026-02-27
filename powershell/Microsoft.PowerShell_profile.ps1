# Microsoft.PowerShell_profile.ps1 — Dotfiles Citadel
# Managed by: https://github.com/geekedsilicon/dotfiles
# Symlinked to:
#   ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1          (PS 7)
#   ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1   (PS 5.1)
#
# Author:  geekedsilicon
# Version: 1.0.0

# ---------------------------------------------------------------------------
# Starship prompt (cross-shell, low overhead)
# ---------------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# ---------------------------------------------------------------------------
# PSReadLine — improved editing & history
# ---------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
Set-Alias -Name vim  -Value nvim          -Option AllScope -Force -ErrorAction SilentlyContinue
Set-Alias -Name g    -Value git           -Option AllScope -Force
Set-Alias -Name la   -Value Get-ChildItem -Option AllScope -Force

function ll { Get-ChildItem -Force @args }

# ---------------------------------------------------------------------------
# Workspace shortcut
# ---------------------------------------------------------------------------
$env:WORKSPACE = "$env:USERPROFILE\workspace"

function ws {
    <#
    .SYNOPSIS  Jump to the workspace directory.
    #>
    Set-Location $env:WORKSPACE
}

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------
function gst  { git status -sb @args }
function glg  { git log --oneline --graph --decorate --all @args }
function gadd { git add @args }
function gcm  { git commit -m @args }
function gpu  { git push @args }
function gpl  { git pull @args }

# ---------------------------------------------------------------------------
# WSL integration
# ---------------------------------------------------------------------------
function wsl-here {
    <#
    .SYNOPSIS  Open a WSL shell in the Windows current directory.
    #>
    wsl --cd (Get-Location).Path
}

# ---------------------------------------------------------------------------
# Profile loaded confirmation (silent in automated contexts)
# ---------------------------------------------------------------------------
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "⚡ Citadel profile loaded  ($($PSVersionTable.PSVersion))" -ForegroundColor DarkCyan
}
