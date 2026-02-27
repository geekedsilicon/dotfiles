# Zenith Refactor — Architecture Reference

> **Dotfiles Citadel** · `docs/architecture/zenith-setup.md`
> Last updated: 2026-02-27

---

## Table of Contents

1. [Overview](#1-overview)
2. [Directory Map](#2-directory-map)
3. [The Gold Zone — Shared NTFS Mount](#3-the-gold-zone--shared-ntfs-mount)
4. [Symlink Graph](#4-symlink-graph)
5. [Bootstrap Flow](#5-bootstrap-flow)
6. [NTFS Permission Hardening](#6-ntfs-permission-hardening)
7. [WSL2 Memory Governor](#7-wsl2-memory-governor)
8. [VS Code Stability Config](#8-vs-code-stability-config)
9. [Adding New Config Files](#9-adding-new-config-files)
10. [Fresh-Machine Restore in 60 Seconds](#10-fresh-machine-restore-in-60-seconds)

---

## 1. Overview

The **Zenith Refactor** is the philosophy behind this repository: every
configuration file that matters lives in **one** canonical location
(`workspace/dotfiles/`), and every tool reads it via a symbolic link.
Nothing is duplicated, nothing gets out of sync.

```
Windows tool          → symlink → dotfiles/...   (NTFS)
WSL2 / Linux tool     → symlink → /mnt/c/.../dotfiles/...
```

The repository lives in `C:\Users\samue\workspace\dotfiles` — the
**Gold Zone**: a path reachable as both `C:\...\workspace` (Windows) and
`/mnt/c/Users/samue/workspace` (WSL2) without any conversion.

---

## 2. Directory Map

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
│   └── wsl.conf                     # Backup — apply to /etc/wsl.conf as root
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
        └── zenith-setup.md          # ← you are here
```

---

## 3. The Gold Zone — Shared NTFS Mount

```
C:\Users\samue\
├── workspace/                       ← Gold Zone (NTFS, dual-visible)
│   └── dotfiles/                    ← This repo
├── .wslconfig                       ← Written by setup.ps1 (not a symlink)
├── AppData\Roaming\Code\User\
│   └── settings.json                ← Symlink → dotfiles/vscode/settings.json
└── Documents\PowerShell\
    └── Microsoft.PowerShell_profile.ps1  ← Symlink → dotfiles/powershell/...

~/  (WSL Ubuntu home)
├── .zshrc                           ← Symlink → /mnt/c/.../dotfiles/wsl/.zshrc
├── .gitconfig                       ← Symlink → /mnt/c/.../dotfiles/wsl/.gitconfig
├── .config/starship.toml            ← Symlink → /mnt/c/.../dotfiles/wsl/starship.toml
└── workspace/                       ← Symlink → /mnt/c/Users/samue/workspace/
```

---

## 4. Symlink Graph

```
dotfiles/wsl/.zshrc  ──────────────────────→  ~/.zshrc
dotfiles/wsl/.bashrc ──────────────────────→  ~/.bashrc
dotfiles/wsl/.gitconfig ───────────────────→  ~/.gitconfig
dotfiles/wsl/starship.toml ─────────────→  ~/.config/starship.toml
dotfiles/vscode/settings.json ─────────────→  %APPDATA%\Code\User\settings.json
                              └────────────→  ~/.config/Code/User/settings.json
dotfiles/powershell/Microsoft.PowerShell_profile.ps1
    ├──────────────────────────────────────→  ~/Documents/PowerShell/…_profile.ps1
    └──────────────────────────────────────→  ~/Documents/WindowsPowerShell/…_profile.ps1
dotfiles/.wslconfig  ──── (copied, not linked) ──→  C:\Users\samue\.wslconfig
```

---

## 5. Bootstrap Flow

### Windows

```powershell
# From an elevated (or Developer Mode) PowerShell terminal:
cd C:\Users\samue\workspace\dotfiles
pwsh -File scripts\setup.ps1
```

`setup.ps1` will:
1. Set `git config core.filemode false` (NTFS hardening)
2. Link PowerShell profile (PS 7 + PS 5.1)
3. Link VS Code `settings.json`
4. Copy `.wslconfig` to `%USERPROFILE%\`
5. Set `cmd.exe` AutoRun registry key

### WSL2 / Ubuntu

```bash
# From the Ubuntu terminal:
cd /mnt/c/Users/samue/workspace/dotfiles
bash scripts/bootstrap.sh
```

`bootstrap.sh` will:
1. Set `git config core.filemode false`
2. Link `.zshrc`, `.bashrc`, `.gitconfig`
3. Link VS Code Linux settings
4. Create `~/workspace` → `/mnt/c/Users/samue/workspace`

### Performance hardening (optional, run once)

```powershell
pwsh -File scripts\citadel.ps1
```

---

## 6. NTFS Permission Hardening

NTFS cannot store POSIX executable bits.  Without mitigation, `git status`
would show every file as modified (mode changed from 644 → 755 or vice versa).

Both bootstrap scripts run:

```bash
git config core.filemode false
```

This tells git to ignore executable-bit changes, preventing spurious diffs
on the NTFS-mounted repository.

**Do not** set this globally (`--global`) — it would affect all your repos,
including Linux-native ones where file mode matters.

---

## 7. WSL2 Memory Governor

File: `.wslconfig` (repo root → copied to `C:\Users\samue\.wslconfig`)

Key settings for the AMD Ryzen AI 7 / 16 GB host:

| Key            | Value | Rationale                                      |
|----------------|-------|------------------------------------------------|
| `memory`       | 6GB   | Prevents WSL2 from ballooning past 6 GB        |
| `processors`   | 4     | Half of physical cores; headroom for Windows   |
| `swap`         | 2GB   | Virtual swap on NTFS; avoids OOM kills in WSL  |
| `pageReporting`| false | Reduces balloon driver churn                   |

After modifying `.wslconfig`, run `wsl --shutdown` from Windows to apply.

---

## 8. VS Code Stability Config

File: `vscode/settings.json`

Critical memory-safety keys:

| Setting                           | Value | Effect                                   |
|-----------------------------------|-------|------------------------------------------|
| `files.watcherExclude`            | (map) | Stops inotify spam on node_modules, dist |
| `files.maxMemoryForLargeFilesMB`  | 256   | Cap per-file memory allocation           |
| `search.followSymlinks`           | false | Prevents infinite traversal of symlinks  |
| `extensions.autoUpdate`           | false | No surprise restarts during coding       |
| `window.restoreWindows`           | none  | Cold start; no session restore overhead  |
| `git.autofetch`                   | false | Manual fetch only                        |

---

## 9. Adding New Config Files

1. **Add the file** to the appropriate directory (`wsl/`, `powershell/`, etc.).
2. **Register the symlink** in the relevant bootstrap script:
   - WSL/Linux targets → `scripts/bootstrap.sh` (`create_symlink` calls)
   - Windows targets   → `scripts/setup.ps1`    (`New-Symlink` calls)
3. **Commit and push** — the symlink will be recreated on the next machine
   by re-running the bootstrap scripts.

### Example: adding a new WSL config file

```bash
# 1. Create the file
touch wsl/.npmrc
echo "prefix=~/.local" >> wsl/.npmrc

# 2. Add to bootstrap.sh
#    create_symlink "$DOTFILES_DIR/wsl/.npmrc" "$HOME_DIR/.npmrc"

# 3. Commit
git add wsl/.npmrc scripts/bootstrap.sh
git commit -m "feat: add .npmrc to WSL configs"
```

---

## 10. Fresh-Machine Restore in 60 Seconds

These steps assume Git and PowerShell 7 (`pwsh`) are already installed.
On a truly bare machine, install them first:

```powershell
winget install Git.Git Microsoft.PowerShell
```

### Step 1 — Clone (≈ 10 s)

```powershell
mkdir C:\Users\$env:USERNAME\workspace
cd    C:\Users\$env:USERNAME\workspace
git clone https://github.com/geekedsilicon/dotfiles.git
```

### Step 2 — Windows symlinks (≈ 5 s)

```powershell
cd C:\Users\$env:USERNAME\workspace\dotfiles
pwsh -File scripts\setup.ps1
```

### Step 3 — WSL2 symlinks (≈ 5 s)

```bash
cd /mnt/c/Users/samue/workspace/dotfiles
bash scripts/bootstrap.sh
```

### Step 4 — Install extensions (≈ 30 s, background)

```bash
cat vscode/extensions.list | grep -v '^#' | grep -v '^$' \
  | xargs -L1 code --install-extension
```

### Step 5 — Performance forge (optional, ≈ 5 s)

```powershell
pwsh -File scripts\citadel.ps1
```

**Total wall time: ≈ 55 seconds** (excluding extension downloads, which run
in the background and do not block the shell).
