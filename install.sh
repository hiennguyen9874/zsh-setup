#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_URL="https://github.com/hiennguyen9874/zsh-setup"
readonly PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"

if [[ -t 1 ]]; then
    readonly BOLD='\033[1m'
    readonly BLUE='\033[34m'
    readonly GREEN='\033[32m'
    readonly YELLOW='\033[33m'
    readonly RED='\033[31m'
    readonly RESET='\033[0m'
else
    readonly BOLD='' BLUE='' GREEN='' YELLOW='' RED='' RESET=''
fi

info() { printf '%b\n' "${BLUE}==>${RESET} $*"; }
success() { printf '%b\n' "${GREEN}✓${RESET} $*"; }
warn() { printf '%b\n' "${YELLOW}!${RESET} $*"; }
die() {
    printf '%b\n' "${RED}Error:${RESET} $*" >&2
    exit 1
}

confirm() {
    local prompt=$1 default=${2:-no} answer
    local choices='[y/N]'
    [[ "$default" == yes ]] && choices='[Y/n]'

    printf '%b ' "$prompt $choices" >&2
    IFS= read -r answer <&3 || return 1
    if [[ -z "$answer" ]]; then
        [[ "$default" == yes ]]
    else
        [[ "$answer" =~ ^[Yy]$ ]]
    fi
}

require_supported_linux() {
    [[ "${OSTYPE:-}" == linux* ]] || die 'Only Linux is supported.'
    [[ $EUID -ne 0 ]] || die 'Run this installer as your normal user, not as root.'
    command -v sudo >/dev/null 2>&1 || die "'sudo' is required."
    [[ -r /etc/os-release ]] || die 'Cannot identify this Linux distribution.'

    # shellcheck disable=SC1091
    . /etc/os-release
    local distro="${ID:-} ${ID_LIKE:-}"
    case "$distro" in
        *debian*|*ubuntu*) PACKAGE_MANAGER=apt ;;
        *fedora*|*rhel*) PACKAGE_MANAGER=dnf ;;
        *arch*) PACKAGE_MANAGER=pacman ;;
        *) die "Unsupported distribution: ${PRETTY_NAME:-unknown}. Supported: Ubuntu/Debian, Fedora, Arch." ;;
    esac
}

show_plan() {
    printf '\n%bMinimal Zsh setup%b\n' "$BOLD" "$RESET"
    printf 'Source: %s\n\n' "$REPO_URL"
    printf '  1. Back up existing Zsh, Oh My Zsh, Powerlevel10k, and Starship files\n'
    printf '  2. Install Zsh and modern CLI tools with sudo (%s)\n' "$PACKAGE_MANAGER"
    printf '  3. Install five focused Zsh plugins\n'
    printf '  4. Install and configure Starship, fzf, zoxide, bat, fd, and ripgrep\n'
    printf '  5. Replace ~/.zshrc and ~/.config/starship.toml\n'
    printf '  6. Set Zsh as the default shell\n\n'
    warn 'Review your backup afterward and restore any personal exports, aliases, or tool initialization.'
}

backup_existing_config() {
    BACKUP_DIR="$HOME/zsh-backup-$(date +%Y%m%d-%H%M%S)"
    install -d -m 0700 "$BACKUP_DIR"

    local source relative
    for source in \
        "$HOME/.zshrc" \
        "$HOME/.zprofile" \
        "$HOME/.zshenv" \
        "$HOME/.zlogin" \
        "$HOME/.p10k.zsh" \
        "$HOME/.oh-my-zsh" \
        "$HOME/powerlevel10k" \
        "$HOME/.config/starship.toml"
    do
        [[ -e "$source" || -L "$source" ]] || continue
        relative=${source#"$HOME"/}
        mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
        cp -a -- "$source" "$BACKUP_DIR/$relative"
    done

    chmod -R go-rwx -- "$BACKUP_DIR"
    success "Private backup created: $BACKUP_DIR"
}

has_legacy_config() {
    [[ -e "$HOME/.oh-my-zsh" || -e "$HOME/.p10k.zsh" || \
       -e "$HOME/powerlevel10k" || \
       -e "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]
}

remove_legacy_config() {
    rm -rf -- \
        "$HOME/.oh-my-zsh" \
        "$HOME/.p10k.zsh" \
        "$HOME/powerlevel10k"

    find "$CACHE_DIR" -maxdepth 1 -name 'p10k-*' -exec rm -rf -- {} + 2>/dev/null || true
    rm -rf -- "$CACHE_DIR/gitstatus"
    success 'Removed Oh My Zsh and Powerlevel10k files.'
}

install_system_packages() {
    info 'Requesting sudo access and installing system packages...'
    sudo -v
    case "$PACKAGE_MANAGER" in
        apt)
            sudo apt-get update
            sudo apt-get install -y zsh git curl fzf bat fd-find ripgrep
            sudo apt-get install -y zoxide || install_zoxide
            ;;
        dnf)
            sudo dnf install -y zsh git curl fzf zoxide bat fd-find ripgrep
            ;;
        pacman)
            sudo pacman -S --needed zsh git curl fzf zoxide bat fd ripgrep
            ;;
    esac
    normalize_cli_names
    success 'Installed Zsh, Git, Curl, fzf, zoxide, bat, fd, and ripgrep.'
}

install_zoxide() {
    warn 'zoxide is unavailable from APT; using its official user installer.'
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

normalize_cli_names() {
    mkdir -p "$HOME/.local/bin"
    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
}

install_plugin() {
    local name=$1 url=$2
    local destination="$PLUGIN_DIR/$name"
    if [[ -d "$destination/.git" ]]; then
        info "Updating $name..."
        git -C "$destination" pull --ff-only
    elif [[ -e "$destination" ]]; then
        die "$destination already exists but is not a Git checkout. Move it and rerun the installer."
    else
        info "Installing $name..."
        git clone --depth=1 "$url" "$destination"
    fi
}

install_plugins() {
    mkdir -p "$PLUGIN_DIR"
    install_plugin zsh-completions \
        https://github.com/zsh-users/zsh-completions.git
    install_plugin fzf-tab \
        https://github.com/Aloxaf/fzf-tab.git
    install_plugin zsh-autosuggestions \
        https://github.com/zsh-users/zsh-autosuggestions.git
    install_plugin zsh-syntax-highlighting \
        https://github.com/zsh-users/zsh-syntax-highlighting.git
    install_plugin zsh-history-substring-search \
        https://github.com/zsh-users/zsh-history-substring-search.git
    success 'Installed Zsh plugins.'
}

install_starship() {
    info 'Installing Starship...'
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://starship.rs/install.sh | \
        sh -s -- -y -b "$HOME/.local/bin"
    "$HOME/.local/bin/starship" --version
    success 'Installed Starship.'
}

write_zshrc() {
    local temp_file
    temp_file=$(mktemp "$HOME/.zshrc.XXXXXX")
    cat > "$temp_file" <<'ZSHRC'
# Minimal Zsh with focused plugins, modern CLI tools, and Starship.

typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" $path)
export PATH

HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_VERIFY EXTENDED_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP CORRECT

bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char

ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
if [[ -d "$ZSH_PLUGIN_DIR/zsh-completions/src" ]]; then
    fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
fi

autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
if [[ -n "$ZSH_COMPDUMP"(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
if [[ -n "$LS_COLORS" ]]; then
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi
zstyle ':completion:*:*:*:*:processes' command \
    'ps -u $USER -o pid,user,comm -w -w'

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias reload='exec zsh'
alias gst='git status'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias dc='docker compose'
alias dps='docker ps'

if command -v bat >/dev/null 2>&1; then
    alias bcat='bat --paging=never'
fi
if command -v fd >/dev/null 2>&1; then
    alias ff='fd'
fi
if command -v rg >/dev/null 2>&1; then
    alias rgi='rg --hidden --glob "!.git"'
fi

# Add personal environment setup (CUDA, Go, Rust, Conda, etc.) here.

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border --info=inline --cycle'
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:300 {}" --preview-window=right:60%'
fi
export FZF_ALT_C_OPTS='--preview "ls --color=always -A {} 2>/dev/null" --preview-window=right:60%'

if command -v fzf >/dev/null 2>&1; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] &&
            source /usr/share/doc/fzf/examples/key-bindings.zsh
        [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] &&
            source /usr/share/doc/fzf/examples/completion.zsh
    fi
fi

if [[ -r "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" ]]; then
    source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
    zstyle ':fzf-tab:*' group-colors \
        $'\033[1;33m' $'\033[1;34m' $'\033[1;35m' $'\033[1;36m'
    zstyle ':fzf-tab:*' switch-group '<' '>'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview \
        'ls --color=always -A $realpath 2>/dev/null'
    zstyle ':fzf-tab:complete:*:*' fzf-preview \
        'if [[ -d $realpath ]]; then
             ls --color=always -A $realpath 2>/dev/null
         elif command -v bat >/dev/null 2>&1; then
             bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null
         fi'
fi

if [[ -r "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
    bindkey '^[[C' forward-char
    bindkey '^ ' autosuggest-accept
fi

if [[ -r "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ -r "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=green,fg=black,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
ZSHRC
    chmod 0644 "$temp_file"
    mv -f -- "$temp_file" "$HOME/.zshrc"
}

write_starship_config() {
    local temp_file
    mkdir -p "$HOME/.config"
    temp_file=$(mktemp "$HOME/.config/starship.toml.XXXXXX")
    cat > "$temp_file" <<'STARSHIP'
# Minimal Starship configuration. No Nerd Font is required.
add_newline = false
command_timeout = 800
scan_timeout = 30

format = """
$directory\
$git_branch\
$git_status\
$python\
$cmd_duration\
$line_break\
$character"""

[directory]
format = "[$path]($style)"
style = "bold blue"
truncation_length = 4
truncate_to_repo = true
read_only = " ro"

[git_branch]
format = " [$branch]($style)"
style = "bold purple"

[git_status]
format = " [$all_status$ahead_behind]($style)"
style = "yellow"
conflicted = "="
ahead = "↑${count}"
behind = "↓${count}"
diverged = "↕↑${ahead_count}↓${behind_count}"
untracked = "?${count}"
stashed = "s${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "r${count}"
deleted = "x${count}"

[python]
format = " [py:$version( $virtualenv)]($style)"
style = "yellow"
detect_extensions = []
detect_files = []
detect_folders = []
python_binary = ["python3", "python"]

[cmd_duration]
min_time = 2000
format = " [$duration]($style)"
style = "yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"
STARSHIP
    chmod 0644 "$temp_file"
    mv -f -- "$temp_file" "$HOME/.config/starship.toml"
}

write_config() {
    mkdir -p "$CACHE_DIR/zsh"
    write_zshrc
    write_starship_config
    rm -f "$CACHE_DIR/zsh/zcompdump"*
    zsh -n "$HOME/.zshrc"
    success 'Wrote and validated ~/.zshrc and ~/.config/starship.toml.'
}

set_default_shell() {
    local zsh_path current_shell
    zsh_path=$(command -v zsh)
    current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    if [[ "$current_shell" == "$zsh_path" ]]; then
        success "Zsh is already the default shell ($zsh_path)."
        return
    fi

    sudo chsh -s "$zsh_path" "$(id -un)"
    success "Default shell changed to $zsh_path."
}

main() {
    exec 3</dev/tty || die 'An interactive terminal is required.'
    require_supported_linux
    show_plan
    confirm 'Continue with the recommended full installation?' || {
        printf 'Installation cancelled.\n'
        exit 0
    }

    info 'Backing up existing configuration...'
    backup_existing_config

    if has_legacy_config; then
        if confirm 'Remove the backed-up Oh My Zsh and Powerlevel10k files?' yes; then
            remove_legacy_config
        else
            warn 'Legacy files kept. The new ~/.zshrc will not load them.'
        fi
    fi

    install_system_packages
    install_plugins
    install_starship
    write_config
    set_default_shell

    printf '\n%bInstallation complete.%b\n' "$BOLD$GREEN" "$RESET"
    printf 'Backup: %s\n' "$BACKUP_DIR"
    printf 'Log out and back in to use Zsh as your default shell.\n'
    printf 'Then review your old .zshrc in the backup and restore personal settings manually.\n'
}

main "$@"
