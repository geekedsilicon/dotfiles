# 🛰️ Dotfiles Citadel

> **Zenith Refactor** — one repo, two environments, zero drift.

A high-performance dotfiles repository managing configurations for a
**Windows 11 host** and an **Ubuntu 24.04 WSL2** environment running on an
AMD Ryzen AI 7 workstation (16 GB RAM).

---

## ⚡ 60-Second Fresh-Machine Restore

```powershell
# Windows — clone to the Gold Zone
mkdir C:\Users\$env:USERNAME\workspace
cd    C:\Users\$env:USERNAME\workspace
git clone https://github.com/geekedsilicon/dotfiles.git
cd dotfiles

# 1. Windows symlinks + .wslconfig
pwsh -File scripts\setup.ps1
```

```bash
# 2. WSL2 symlinks (run inside Ubuntu)
cd /mnt/c/Users/samue/workspace/dotfiles
bash scripts/bootstrap.sh
```

```bash
# 3. Install VS Code extensions (runs in background)
cat vscode/extensions.list | grep -v '^#' | grep -v '^$' \
  | xargs -L1 code --install-extension
```

---

## 📁 Repository Structure

```
dotfiles/
├── .wslconfig                       # WSL2 resource governor (6 GB cap)
├── README.md
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── wsl/
│   ├── .zshrc
│   ├── .bashrc
│   ├── .gitconfig
│   ├── starship.toml
│   └── wsl.conf                     # Backup of /etc/wsl.conf
├── vscode/
│   ├── settings.json
│   └── extensions.list
├── cmd/
│   └── cmd_profile.cmd
├── scripts/
│   ├── bootstrap.sh                 # WSL2 symlink installer
│   ├── setup.ps1                    # Windows symlink installer
│   └── citadel.ps1                  # Performance & Stability Forge
└── docs/
    └── architecture/
        └── zenith-setup.md
```

---

## 🗺️ Symlink Map

| Repo file | Live location |
|-----------|--------------|
| `wsl/.zshrc` | `~/.zshrc` |
| `wsl/.bashrc` | `~/.bashrc` |
| `wsl/.gitconfig` | `~/.gitconfig` |
| `wsl/starship.toml` | `~/.config/starship.toml` |
| `vscode/settings.json` | `%APPDATA%\Code\User\settings.json` (Win) / `~/.config/Code/User/settings.json` (WSL) |
| `powershell/Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/` & `~/Documents/WindowsPowerShell/` |
| `.wslconfig` | `C:\Users\samue\.wslconfig` (copied, not linked) |

---

## 🛠️ Scripts

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/bootstrap.sh` | WSL2/Ubuntu | Creates Linux symlinks, NTFS hardening |
| `scripts/setup.ps1` | Windows/PowerShell | Creates Windows symlinks, copies `.wslconfig` |
| `scripts/citadel.ps1` | Windows/PowerShell | Performance & stability forge |

### Dry-run mode

Both bootstrap scripts support `--dry-run` / `-DryRun` to preview changes
without touching the filesystem:

```bash
bash scripts/bootstrap.sh --dry-run
pwsh -File scripts\setup.ps1 -DryRun
```

---

## ➕ Adding New Config Files

1. Drop the file into the correct directory (`wsl/`, `powershell/`, etc.).
2. Register the symlink in `scripts/bootstrap.sh` or `scripts/setup.ps1`.
3. Commit and push — the link is recreated on the next machine by re-running
   the bootstrap scripts.

See [`docs/architecture/zenith-setup.md`](docs/architecture/zenith-setup.md)
for the full architecture reference.

---

## 🧠 Memory Safety (AMD Ryzen AI 7 / 16 GB)

- **WSL2** is capped at 6 GB via `.wslconfig` — prevents balloon-driver
  exhaustion during long coding sessions.
- **VS Code** has `files.watcherExclude`, `search.followSymlinks: false`, and
  `window.restoreWindows: none` set to prevent inotify storms.
- Run `scripts/citadel.ps1` to validate and tighten all settings at once.

---

## 📖 Architecture

Full details: [`docs/architecture/zenith-setup.md`](docs/architecture/zenith-setup.md)