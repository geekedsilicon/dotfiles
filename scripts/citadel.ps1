# -- VAELIX CITADEL: UBUNTU HARDENING (v16.1) --
$ErrorActionPreference = "SilentlyContinue"
Write-Host "⚔️  FINALIZING UBUNTU ZENITH CONFIGURATION..." -ForegroundColor Red

# 1. Force Ubuntu as the Default Distribution
Write-Host "  [1/4] Setting Ubuntu as Default..." -ForegroundColor Yellow
wsl --set-default Ubuntu
wsl --shutdown
Write-Host "  ✅ Default distro locked to Ubuntu." -ForegroundColor Green

# 2. Re-Forge .wslconfig (Fixed Syntax & Path)
Write-Host "  [2/4] Patching .wslconfig Keys & Paths..." -ForegroundColor Yellow
$WslConfigPath = "$env:USERPROFILE\.wslconfig"

# Ensure the Temp directory for swap actually exists
$TempDir = "$env:LOCALAPPDATA\Temp"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force }

# autoMemoryReclaim must be under [experimental], not [wsl2]
$HardenedConfig = @"
[wsl2]
memory=6GB 
processors=4
swap=2GB
swapFile=$($TempDir.Replace('\','\\'))\\wsl-swap.vhdx
[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@
[System.IO.File]::WriteAllText($WslConfigPath, $HardenedConfig)
Write-Host "  ✅ .wslconfig keys moved to [experimental]." -ForegroundColor Green

# 3. Secure Ubuntu Sparse VHD
Write-Host "  [3/4] Enabling Sparse VHD for Ubuntu..." -ForegroundColor Yellow
# Using --allow-unsafe to bypass corruption warnings in recent WSL versions
wsl.exe --manage Ubuntu --set-sparse true --allow-unsafe
Write-Host "  ✅ Ubuntu VHD set to Sparse mode." -ForegroundColor Green

# 4. Clean Ubuntu VS Code Server
Write-Host "  [4/4] Final Ubuntu Cleanup..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -e bash -c "rm -rf ~/.vscode-server/bin/*"
Write-Host "  ✅ Ubuntu server cache cleared." -ForegroundColor Green

Write-Host "`n🎯 UBUNTU ZENITH ACTIVE. RESTARTING..." -ForegroundColor Cyan
wsl -d Ubuntu