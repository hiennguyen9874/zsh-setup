#!/usr/bin/env bash

set -Eeuo pipefail

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
    local prompt=$1 answer
    printf '%b ' "$prompt [y/N]" >&2
    IFS= read -r answer <&3 || return 1
    [[ "$answer" =~ ^[Yy]$ ]]
}

require_supported_linux() {
    [[ "${OSTYPE:-}" == linux* ]] || die 'Only Linux is supported.'
    [[ $EUID -ne 0 ]] || die 'Run this uninstaller as your normal user, not as root.'
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
    printf '\n%bRemove the Zsh setup%b\n\n' "$BOLD" "$RESET"
    printf '  1. Back up Zsh configuration, history, plugins, and user-installed binaries\n'
    printf '  2. Change the login shell to Bash if it currently uses Zsh\n'
    printf '  3. Remove Zsh, Oh My Zsh, Powerlevel10k, plugins, Starship, and caches\n'
    printf '  4. Uninstall Zsh, Git, Curl, fzf, zoxide, bat, fd, and ripgrep packages (%s)\n\n' "$PACKAGE_MANAGER"
    warn 'This removes the full bundle even if some components existed before install.sh was run.'
    warn 'The backup is not restored automatically.'
}

backup_existing_setup() {
    BACKUP_DIR="$HOME/zsh-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    install -d -m 0700 "$BACKUP_DIR"

    local source relative
    for source in \
        "$HOME/.zshrc" \
        "$HOME/.zprofile" \
        "$HOME/.zshenv" \
        "$HOME/.zlogin" \
        "$HOME/.zlogout" \
        "$HOME/.zsh_history" \
        "$HOME/.p10k.zsh" \
        "$HOME/.oh-my-zsh" \
        "$HOME/powerlevel10k" \
        "$HOME/.config/starship.toml" \
        "$HOME/.local/share/zsh" \
        "$HOME/.local/share/zoxide" \
        "$HOME/.local/bin/starship" \
        "$HOME/.local/bin/zoxide" \
        "$HOME/.local/bin/bat" \
        "$HOME/.local/bin/fd"
    do
        [[ -e "$source" || -L "$source" ]] || continue
        relative=${source#"$HOME"/}
        mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
        cp -a -- "$source" "$BACKUP_DIR/$relative"
    done

    chmod -R go-rwx -- "$BACKUP_DIR"
    success "Private backup created: $BACKUP_DIR"
}

set_bash_as_default_shell() {
    local current_shell bash_path
    current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    [[ "${current_shell##*/}" == zsh ]] || {
        success "Login shell is already $current_shell; no change needed."
        return
    }

    bash_path=$(command -v bash 2>/dev/null) || die 'Bash is required before Zsh can be removed.'
    if [[ -r /etc/shells ]] && ! grep -Fqx "$bash_path" /etc/shells; then
        [[ -x /bin/bash ]] && grep -Fqx /bin/bash /etc/shells && bash_path=/bin/bash
    fi

    info "Changing the login shell to $bash_path..."
    sudo chsh -s "$bash_path" "$(id -un)" ||
        die 'Could not change the login shell. Zsh has not been uninstalled.'
    success "Default shell changed to $bash_path."
}

package_is_installed() {
    local package=$1
    case "$PACKAGE_MANAGER" in
        apt)
            dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null |
                grep -q '^ii'
            ;;
        dnf) rpm -q "$package" >/dev/null 2>&1 ;;
        pacman) pacman -Q "$package" >/dev/null 2>&1 ;;
    esac
}

remove_system_packages() {
    local candidates=() installed=() package
    case "$PACKAGE_MANAGER" in
        apt) candidates=(zsh git curl fzf zoxide bat fd-find ripgrep) ;;
        dnf) candidates=(zsh git curl fzf zoxide bat fd-find ripgrep) ;;
        pacman) candidates=(zsh git curl fzf zoxide bat fd ripgrep) ;;
    esac

    for package in "${candidates[@]}"; do
        package_is_installed "$package" && installed+=("$package")
    done

    if ((${#installed[@]} == 0)); then
        success 'No matching system packages are installed.'
        return
    fi

    info "Removing system packages: ${installed[*]}"
    sudo -v
    case "$PACKAGE_MANAGER" in
        apt) sudo apt-get remove -y "${installed[@]}" ;;
        dnf) sudo dnf remove -y "${installed[@]}" ;;
        pacman) sudo pacman -R --noconfirm "${installed[@]}" ;;
    esac
    success 'Removed system packages.'
}

remove_user_files() {
    rm -rf -- \
        "$HOME/.zshrc" \
        "$HOME/.zprofile" \
        "$HOME/.zshenv" \
        "$HOME/.zlogin" \
        "$HOME/.zlogout" \
        "$HOME/.zsh_history" \
        "$HOME/.p10k.zsh" \
        "$HOME/.oh-my-zsh" \
        "$HOME/powerlevel10k" \
        "$HOME/.config/starship.toml" \
        "$HOME/.local/share/zsh" \
        "$HOME/.local/share/zoxide" \
        "$HOME/.local/bin/starship" \
        "$HOME/.local/bin/zoxide"

    # install.sh creates these compatibility links only when the native command
    # has a distribution-specific name. Do not remove unrelated regular files.
    if [[ -L "$HOME/.local/bin/bat" ]]; then
        rm -f -- "$HOME/.local/bin/bat"
    fi
    if [[ -L "$HOME/.local/bin/fd" ]]; then
        rm -f -- "$HOME/.local/bin/fd"
    fi

    rm -rf -- "$CACHE_DIR/zsh" "$CACHE_DIR/gitstatus"
    find "$CACHE_DIR" -maxdepth 1 -name 'p10k-*' -exec rm -rf -- {} + 2>/dev/null || true

    rmdir "$HOME/.local/share/zsh" "$HOME/.local/share" "$HOME/.local/bin" \
        "$HOME/.local" "$HOME/.config" 2>/dev/null || true
    success 'Removed Zsh configuration, plugins, prompts, user binaries, and caches.'
}

main() {
    exec 3</dev/tty || die 'An interactive terminal is required.'
    require_supported_linux
    show_plan
    confirm 'Continue with the full uninstall?' || {
        printf 'Uninstall cancelled.\n'
        exit 0
    }

    info 'Backing up the current setup...'
    backup_existing_setup
    set_bash_as_default_shell
    remove_system_packages
    remove_user_files

    printf '\n%bUninstall complete.%b\n' "$BOLD$GREEN" "$RESET"
    printf 'Backup: %s\n' "$BACKUP_DIR"
    printf 'Log out and back in to start using Bash as your login shell.\n'
}

main "$@"
