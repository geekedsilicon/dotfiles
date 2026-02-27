#!/usr/bin/env bash
# =============================================================================
# scripts/bootstrap.sh — Dotfiles Citadel  ·  WSL2/Ubuntu symlink installer
# =============================================================================
# @description  Creates symbolic links from this repository to their live
#               locations inside an Ubuntu 24.04 WSL2 environment.
#               Handles NTFS-to-Linux permission quirks and ensures every
#               target directory exists before linking.
#
#               The repository is assumed to live at
#               /mnt/c/Users/<WIN_USER>/workspace/dotfiles
#               (i.e., inside the NTFS "Gold Zone" visible to both Windows
#               and WSL2).
#
# @usage        bash scripts/bootstrap.sh [--dry-run]
# @param        --dry-run  Print what would happen without making changes.
# @author       geekedsilicon
# @version      1.0.0
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repository root (parent of the scripts/ directory)
# ---------------------------------------------------------------------------

# @const {string} SCRIPT_DIR  Absolute path of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# @const {string} DOTFILES_DIR  Absolute path of the repository root.
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# @const {string} HOME_DIR  Current user's home directory.
HOME_DIR="${HOME}"

# @const {boolean} DRY_RUN  When true, no filesystem changes are made.
DRY_RUN=false

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) log_error "Unknown argument: $arg"; exit 1 ;;
  esac
done

$DRY_RUN && log_warn "DRY-RUN mode — no changes will be written."

# ---------------------------------------------------------------------------
# @function create_symlink
# @description  Creates a symbolic link $dest → $src, backing up any
#               pre-existing regular file at $dest.
# @param {string} src   Source path inside the dotfiles repository.
# @param {string} dest  Destination path on the live system.
# ---------------------------------------------------------------------------
create_symlink() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  # Ensure source exists.
  if [[ ! -e "$src" ]]; then
    log_warn "Source not found, skipping: $src"
    return
  fi

  # Ensure parent directory exists.
  if [[ ! -d "$dest_dir" ]]; then
    log_info "Creating directory: $dest_dir"
    $DRY_RUN || mkdir -p "$dest_dir"
  fi

  # Back up existing regular file.
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%dT%H%M%S)"
    log_warn "Backing up existing file: $dest → $backup"
    $DRY_RUN || mv "$dest" "$backup"
  elif [[ -L "$dest" ]]; then
    log_warn "Removing stale symlink: $dest"
    $DRY_RUN || rm "$dest"
  fi

  log_info "Linking: $src → $dest"
  $DRY_RUN || ln -sf "$src" "$dest"
  log_success "Linked: $dest"
}

# ---------------------------------------------------------------------------
# @function harden_git_filemode
# @description  Sets git core.filemode = false so that NTFS mounts (which
#               cannot represent POSIX permissions) do not cause spurious diffs.
# ---------------------------------------------------------------------------
harden_git_filemode() {
  log_info "Setting git core.filemode = false (NTFS hardening)"
  $DRY_RUN || git -C "$DOTFILES_DIR" config core.filemode false
  log_success "core.filemode = false"
}

# ---------------------------------------------------------------------------
# @function link_wsl_configs
# @description  Links WSL shell and git configuration files to Linux home.
# ---------------------------------------------------------------------------
link_wsl_configs() {
  log_info "=== WSL / shell configs ==="
  create_symlink "$DOTFILES_DIR/wsl/.zshrc"        "$HOME_DIR/.zshrc"
  create_symlink "$DOTFILES_DIR/wsl/.bashrc"       "$HOME_DIR/.bashrc"
  create_symlink "$DOTFILES_DIR/wsl/.gitconfig"    "$HOME_DIR/.gitconfig"
  create_symlink "$DOTFILES_DIR/wsl/starship.toml" "$HOME_DIR/.config/starship.toml"
}

# ---------------------------------------------------------------------------
# @function link_vscode_configs
# @description  Links VS Code user settings to the Linux VS Code config path.
# ---------------------------------------------------------------------------
link_vscode_configs() {
  log_info "=== VS Code configs ==="
  local vscode_user_dir="$HOME_DIR/.config/Code/User"
  create_symlink "$DOTFILES_DIR/vscode/settings.json" "$vscode_user_dir/settings.json"
}

# ---------------------------------------------------------------------------
# @function link_workspace
# @description  Creates ~/workspace as a convenience symlink to the NTFS
#               Gold Zone visible to both Windows and WSL2.
# ---------------------------------------------------------------------------
link_workspace() {
  log_info "=== Workspace symlink ==="
  # Derive the Windows user directory from the repo path under /mnt/c/
  # e.g. /mnt/c/Users/samue/workspace/dotfiles → /mnt/c/Users/samue/workspace
  local win_workspace
  win_workspace="$(dirname "$DOTFILES_DIR")"

  if [[ "$win_workspace" == /mnt/* ]]; then
    create_symlink "$win_workspace" "$HOME_DIR/workspace"
  else
    log_warn "Repository is not on an NTFS mount; skipping workspace symlink."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  log_info "Dotfiles Citadel — bootstrap starting"
  log_info "Repository root : $DOTFILES_DIR"
  log_info "WSL home        : $HOME_DIR"

  harden_git_filemode
  link_wsl_configs
  link_vscode_configs
  link_workspace

  log_success "Bootstrap complete.  Reload your shell:  exec \$SHELL"
}

main "$@"
