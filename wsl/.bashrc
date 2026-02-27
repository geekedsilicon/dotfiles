# ~/.bashrc — Dotfiles Citadel (WSL2 / Ubuntu 24.04)
# Managed by: https://github.com/geekedsilicon/dotfiles

# Return immediately for non-interactive shells.
case $- in
  *i*) ;;
    *) return ;;
esac

# ---------------------------------------------------------------------------
# Prompt (Starship, with fallback)
# ---------------------------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
command -v starship &>/dev/null && eval "$(starship init bash)"

# ---------------------------------------------------------------------------
# Path
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# ---------------------------------------------------------------------------
# Aliases (shared with .zshrc for consistency)
# ---------------------------------------------------------------------------
alias ll="ls -lAh --color=auto"
alias la="ls -A --color=auto"
alias grep="grep --color=auto"
alias vim="nvim"
alias g="git"
alias dc="docker compose"
alias explorer='explorer.exe .'

# ---------------------------------------------------------------------------
# WSL2
# ---------------------------------------------------------------------------
export WSLENV=USERPROFILE/p:APPDATA/p

# Enable colour support for common tools
if [ -x /usr/bin/dircolors ]; then
  eval "$(dircolors -b)"
fi
