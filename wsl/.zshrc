# ══════════════════════════════════════════════════════════════════
#  VAELIX CITADEL: ZSH PROFILE  (v13.0)
# ══════════════════════════════════════════════════════════════════

# ── Performance: skip compinit check on every launch ─────────────
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ── PATH ──────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.local/share/fnm:$PATH"

# ── History ───────────────────────────────────────────────────────
export HISTSIZE=50000
export SAVEHIST=50000
export HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE   # lines starting with space are not saved
setopt SHARE_HISTORY       # share history across terminals
setopt EXTENDED_HISTORY    # save timestamps

# ── Zsh Options ───────────────────────────────────────────────────
setopt AUTO_CD             # type a dir name to cd into it
setopt AUTO_PUSHD          # cd pushes old dir onto stack
setopt PUSHD_IGNORE_DUPS
setopt CORRECT             # spell correction
setopt GLOB_DOTS           # dot files in globs without leading dot
setopt NO_BEEP

# ── 1. fzf-tab (must load BEFORE other completion widgets) ────────
[[ -f ~/.zsh/fzf-tab/fzf-tab.plugin.zsh ]] && source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# ── 2. Zsh Completions ────────────────────────────────────────────
[[ -d ~/.zsh/zsh-completions/src ]] && fpath=(~/.zsh/zsh-completions/src $fpath)

# ── 3. Syntax Highlighting ────────────────────────────────────────
#    fast-syntax-highlighting is more feature-rich; fall back to zsh-syntax-highlighting
if [[ -f ~/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source ~/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
elif [[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ── 4. Autosuggestions ────────────────────────────────────────────
if [[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70,bold"
    # Accept suggestion with → or Ctrl+Space
    bindkey '^ ' autosuggest-accept
    bindkey '^[[C' autosuggest-accept
fi

# ── 5. FZF ────────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    # Source shell integration if available from apt package
    [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -f /usr/share/doc/fzf/examples/completion.zsh   ]] && \
        source /usr/share/doc/fzf/examples/completion.zsh

    # FZF appearance — Catppuccin Macchiato palette
    export FZF_DEFAULT_OPTS="
        --height 40% --layout=reverse --border rounded
        --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
        --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
        --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796
        --bind 'ctrl-/:toggle-preview'
    "
    # Use fd for file searching if available
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Ctrl+R = fuzzy history | Ctrl+T = fuzzy files | Alt+C = fuzzy cd
    bindkey '^R' fzf-history-widget
    bindkey '^T' fzf-file-widget
fi

# ── 6. Oh My Posh ─────────────────────────────────────────────────
if command -v oh-my-posh &>/dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/catppuccin_macchiato.omp.json)"
fi

# ── 7. Key Bindings ───────────────────────────────────────────────
bindkey '^[[A' history-search-backward   # Up arrow
bindkey '^[[B' history-search-forward    # Down arrow
bindkey '^[[H' beginning-of-line         # Home
bindkey '^[[F' end-of-line               # End
bindkey '^[[3~' delete-char              # Delete
bindkey '^[[1;5C' forward-word           # Ctrl+Right
bindkey '^[[1;5D' backward-word          # Ctrl+Left

# ── 8. Aliases ────────────────────────────────────────────────────
# File listing
alias ls='lsd'
alias ll='lsd -la'
alias lt='lsd --tree --depth 2'
alias la='lsd -A'

# Cat replacement
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
elif command -v batcat &>/dev/null; then
    alias cat='batcat --paging=never'
    alias less='batcat --paging=always'
fi

# Core utils
alias c='clear'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'          # Interactive delete — saves you from accidents
alias df='df -h'
alias du='du -sh'
alias free='free -h'

# Git
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gl='git log --oneline --graph --decorate --all | head -30'
alias gd='git diff'
alias gst='git stash'

# Docker
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images'
alias dex='docker exec -it'

# Node / NPM
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'

# System
alias ports='ss -tulnp'          # All open ports
alias myip='curl -s https://api.ipify.org && echo'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc && echo "✅ .zshrc reloaded."'
alias zshconfig='${EDITOR:-nano} ~/.zshrc'

# ── 9. Functions ──────────────────────────────────────────────────

# Kill process on port
nuke-port() {
    if [[ -z "$1" ]]; then echo "Usage: nuke-port <port>"; return 1; fi
    echo "🚀 Targeting port $1..."
    local pid
    pid=$(lsof -ti tcp:"$1" 2>/dev/null || ss -tlnp | grep ":$1 " | grep -oP '(?<=pid=)\d+' || true)
    if [[ -n "$pid" ]]; then
        kill -9 $pid
        echo "💥 PID $pid neutralized on port $1."
    else
        echo "✅ Sector clear. Nothing on port $1."
    fi
}

# Docker full purge
docker-purge() {
    echo "🧹 Deep sweep of all Docker artifacts..."
    docker system prune -a --volumes -f
    echo "✅ Docker matrix sanitized."
}

# Recursive clean of build artifacts
vacuum-repo() {
    echo "🌪️  Purging node_modules / dist / .next / build / __pycache__ ..."
    find . \( -name "node_modules" -o -name "dist" -o -name ".next" \
           -o -name "build"        -o -name "__pycache__" \) \
        -type d -prune -exec rm -rf {} +
    echo "✅ Airflow restored."
}

# Make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Quick grep through project files
search() {
    if command -v rg &>/dev/null; then
        rg --smart-case "$@"
    else
        grep -r --color=auto "$@" .
    fi
}

# Fuzzy cd using fzf + fd
fcd() {
    local dir
    dir=$(fd --type d --hidden --exclude .git 2>/dev/null | fzf --preview 'lsd --color=always {}')
    [[ -n "$dir" ]] && cd "$dir"
}

# Extract any archive format
extract() {
    case "$1" in
        *.tar.bz2) tar xjf "$1"  ;;
        *.tar.gz)  tar xzf "$1"  ;;
        *.tar.xz)  tar xJf "$1"  ;;
        *.zip)     unzip  "$1"   ;;
        *.gz)      gunzip "$1"   ;;
        *.7z)      7z x   "$1"   ;;
        *)         echo "Unknown archive type: $1" ;;
    esac
}

# Git interactive branch switcher via fzf
gbr() {
    local branch
    branch=$(git branch --all | fzf --ansi | sed 's|remotes/origin/||' | tr -d ' ')
    [[ -n "$branch" ]] && git checkout "$branch"
}

# Show top 10 disk usage
topdisk() { du -sh "${1:-.}"/* 2>/dev/null | sort -rh | head -10; }

# HTTP request inspector
headers() { curl -sI "$1" | bat --language http --paging=never 2>/dev/null || curl -sI "$1"; }

# ── 10. FNM (Node Version Manager) ───────────────────────────────
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# ── 11. Vaelix Project Shortcuts ─────────────────────────────────
alias vaelix='cd ~/workspace/projects/vaelix-command-dashb'
alias vanguard-up='cd ~/workspace/projects/vaelix-command-dashb && npm run dev:citadel'
alias ai-local='ollama run llama3'

# ── 12. WSL-specific tweaks ───────────────────────────────────────
# Open Windows Explorer from current directory
alias explorer='explorer.exe .'
# Clipboard pipe: echo "text" | clip
alias clip='clip.exe'
# Open VS Code from WSL with Windows-side server
alias code='code.exe'

# ── 13. Greeting ──────────────────────────────────────────────────
echo ""
echo -e "  \033[0;36m✅ Vaelix Linux Zenith Loaded\033[0m  \033[0;90m$(uname -sr) | $(date '+%a %d %b %Y %H:%M')\033[0m"
echo ""

# ── VAELIX ZENITH: RUNTIME REPAIR ──
# Fixes fnm multishells and systemd user session errors on startup
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR/fnm_multishells"
    sudo chown -R $(whoami):$(whoami) "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR="/tmp/run/user/$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR/fnm_multishells"
export PATH="$HOME/.local/bin:$PATH"
eval "$(fnm env --use-on-cd --shell zsh)"
export XDG_RUNTIME_DIR="/tmp/run/user/$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR/fnm_multishells"
eval "$(fnm env --use-on-cd --shell zsh)"
alias zenith='sudo bash -c "echo nameserver 8.8.8.8 > /etc/resolv.conf" && cd /mnt/c/Users/samue/workspace/dotfiles && git pull && git add . && git commit -m "chore: auto-sync zenith" && git push && source ~/.zshrc && echo "🚀 Zenith System Fully Synced and Nominal."' 
alias zenith='sudo bash -c "echo nameserver 8.8.8.8 > /etc/resolv.conf" && cd /mnt/c/Users/samue/workspace/dotfiles && git pull origin main && git add . && git commit -m "chore: auto-sync zenith" && git push origin main && source ~/.zshrc && echo "🚀 Zenith System Fully Synced and Nominal."' 
